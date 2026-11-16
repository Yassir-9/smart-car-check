const test = require('node:test');
const assert = require('node:assert/strict');
const gemini = require('../services/ai/geminiProvider');

const OK = { ok: true, status: 200, json: async () => ({ candidates: [{ content: { parts: [{ text: 'ok' }] } }] }) };
const status = (code, retryAfter) => ({
  ok: false, status: code, headers: { get: () => retryAfter ?? null }, json: async () => ({}),
});
// A fetch that never answers until its own AbortSignal fires.
const hang = (_url, options) => new Promise((_, reject) => {
  options.signal.addEventListener('abort', () => {
    const error = new Error('aborted');
    error.name = 'AbortError';
    reject(error);
  });
});

async function withEnv(env, fn) {
  const saved = {};
  const full = { GEMINI_API_KEY: 'unit-test-key', ...env };
  for (const [k, v] of Object.entries(full)) { saved[k] = process.env[k]; process.env[k] = v; }
  const originalFetch = global.fetch;
  const originalWarn = console.warn;
  console.warn = () => {};
  try { return await fn(); } finally {
    global.fetch = originalFetch;
    console.warn = originalWarn;
    for (const [k, v] of Object.entries(saved)) { if (v === undefined) delete process.env[k]; else process.env[k] = v; }
  }
}

test('a later attempt still has its own timeout (503 then a hanging request)', () => withEnv(
  { GEMINI_ATTEMPT_TIMEOUT_MS: '60', GEMINI_TOTAL_TIMEOUT_MS: '2000', GEMINI_RETRY_BASE_MS: '1' },
  async () => {
    let calls = 0;
    global.fetch = async (url, options) => {
      calls += 1;
      if (calls === 1) return status(503);
      return hang(url, options);
    };
    const startedAt = Date.now();
    await assert.rejects(gemini.generateText({ system: 's', prompt: 'p' }), (error) => {
      assert.equal(error.code, 'AI_TIMEOUT');
      assert.equal(error.timedOut, true);
      assert.match(error.message, /timed out/);
      return true;
    });
    assert.equal(calls, 2);
    assert.ok(Date.now() - startedAt < 1500, 'the hanging attempt must be cut by its own timer');
  },
));

test('429 is retried with growing delays and then succeeds', () => withEnv(
  { GEMINI_RETRY_BASE_MS: '20', GEMINI_ATTEMPT_TIMEOUT_MS: '1000', GEMINI_TOTAL_TIMEOUT_MS: '5000' },
  async () => {
    const times = [];
    global.fetch = async () => {
      times.push(Date.now());
      return times.length < 3 ? status(429) : OK;
    };
    assert.equal(await gemini.generateText({ system: 's', prompt: 'p' }), 'ok');
    assert.equal(times.length, 3);
    // call 2 is the immediate fallback-model switch; the wait happens before call 3
    assert.ok(times[2] - times[1] >= 15, 'waits before the last attempt');
  },
));

test('the total ceiling stops retries even when Retry-After is long', () => withEnv(
  { GEMINI_ATTEMPT_TIMEOUT_MS: '1000', GEMINI_TOTAL_TIMEOUT_MS: '300', GEMINI_RETRY_BASE_MS: '1' },
  async () => {
    let calls = 0;
    global.fetch = async () => { calls += 1; return status(503, '3600'); };
    const startedAt = Date.now();
    await assert.rejects(gemini.generateText({ system: 's', prompt: 'p' }), /status 503/);
    assert.ok(Date.now() - startedAt < 1000, 'must not sleep for the capped Retry-After');
    assert.ok(calls <= 3);
  },
));

test('backoff grows exponentially and is capped (Retry-After too)', () => withEnv(
  { GEMINI_RETRY_BASE_MS: '1000' },
  async () => {
    const d1 = gemini.retryDelayMs(1);
    const d2 = gemini.retryDelayMs(2);
    const d3 = gemini.retryDelayMs(3);
    assert.ok(d1 >= 1000 && d1 < 1300, String(d1));
    assert.ok(d2 >= 2000 && d2 < 2300, String(d2));
    assert.ok(d3 >= 4000 && d3 < 4300, String(d3));
    assert.equal(gemini.retryDelayMs(10), 8000);
    assert.equal(gemini.retryDelayMs(1, '3600'), 8000);
    assert.equal(gemini.retryDelayMs(1, '2'), 2000);
  },
));

test('server errors (500) are retried too', () => withEnv(
  { GEMINI_RETRY_BASE_MS: '1', GEMINI_ATTEMPT_TIMEOUT_MS: '1000', GEMINI_TOTAL_TIMEOUT_MS: '5000' },
  async () => {
    let calls = 0;
    global.fetch = async () => { calls += 1; return calls < 2 ? status(500) : OK; };
    assert.equal(await gemini.generateText({ system: 's', prompt: 'p' }), 'ok');
    assert.equal(calls, 2);
  },
));
