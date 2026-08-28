const test = require('node:test');
const assert = require('node:assert/strict');

const gemini = require('../services/ai/geminiProvider');

test('normalizes Gemini model IDs without duplicating models path', () => {
  assert.equal(gemini.modelId('gemini-3.7-flash'), 'gemini-3.7-flash');
  assert.equal(gemini.modelId('models/gemini-3.7-flash'), 'gemini-3.7-flash');
  assert.equal(
    new URL(gemini.endpointFor(gemini.modelId('models/gemini-3.7-flash')))
      .pathname,
    '/v1beta/models/gemini-3.7-flash:generateContent',
  );
});

test('rejects malformed Gemini model IDs', () => {
  assert.throws(() => gemini.modelId('gemini/unsafe'), /valid Gemini model ID/);
});

test('sends symptoms and image together without putting the API key in the URL', async () => {
  const originalFetch = global.fetch;
  const originalKey = process.env.GEMINI_API_KEY;
  const originalModel = process.env.AI_MODEL;
  let request;
  process.env.GEMINI_API_KEY = 'unit-test-secret-key';
  process.env.AI_MODEL = 'gemini-3.7-flash';
  global.fetch = async (url, options) => {
    request = { url, options };
    return {
      ok: true,
      status: 200,
      json: async () => ({ candidates: [{ content: { parts: [{ text: '{"ok":true}' }] } }] }),
    };
  };
  try {
    await gemini.generateJson({
      system: 'safe system prompt',
      prompt: 'symptoms and OBD context',
      image: { data: 'aW1hZ2U=', media_type: 'image/png' },
    });
    assert.doesNotMatch(request.url, /unit-test-secret-key/);
    assert.equal(request.options.headers['x-goog-api-key'], 'unit-test-secret-key');
    const body = JSON.parse(request.options.body);
    assert.deepEqual(body.contents[0].parts, [
      { inlineData: { mimeType: 'image/png', data: 'aW1hZ2U=' } },
      { text: 'symptoms and OBD context' },
    ]);
  } finally {
    global.fetch = originalFetch;
    if (originalKey == null) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = originalKey;
    if (originalModel == null) delete process.env.AI_MODEL;
    else process.env.AI_MODEL = originalModel;
  }
});

test('handles Gemini HTTP failures without logging secrets or image data', async () => {
  const originalFetch = global.fetch;
  const originalWarn = console.warn;
  const originalKey = process.env.GEMINI_API_KEY;
  const originalBase = process.env.GEMINI_RETRY_BASE_MS;
  process.env.GEMINI_RETRY_BASE_MS = '0';
  const logs = [];
  process.env.GEMINI_API_KEY = 'unit-test-secret-key';
  console.warn = (...values) => logs.push(values);
  try {
    for (const status of [400, 401, 403, 404, 429, 500, 503]) {
      global.fetch = async () => ({
        ok: false,
        status,
        json: async () => ({ error: { message: `safe error ${status}` } }),
      });
      await assert.rejects(
        gemini.generateJson({
          system: 'system',
          prompt: 'private symptoms',
          image: { data: 'private-base64-image', media_type: 'image/jpeg' },
        }),
        new RegExp(`status ${status}`),
      );
    }
    const serializedLogs = JSON.stringify(logs);
    assert.doesNotMatch(serializedLogs, /unit-test-secret-key/);
    assert.doesNotMatch(serializedLogs, /private-base64-image/);
    assert.doesNotMatch(serializedLogs, /private symptoms/);
  } finally {
    global.fetch = originalFetch;
    console.warn = originalWarn;
    if (originalKey == null) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = originalKey;
    if (originalBase == null) delete process.env.GEMINI_RETRY_BASE_MS;
    else process.env.GEMINI_RETRY_BASE_MS = originalBase;
  }
});

test('retries transient Gemini failures three times and respects Retry-After', async () => {
  const originalFetch = global.fetch;
  const originalKey = process.env.GEMINI_API_KEY;
  const originalBase = process.env.GEMINI_RETRY_BASE_MS;
  process.env.GEMINI_API_KEY = 'unit-test-key';
  process.env.GEMINI_RETRY_BASE_MS = '0';
  let calls = 0;
  try {
    global.fetch = async () => {
      calls += 1;
      if (calls < 3) return { ok: false, status: 503, headers: { get: () => '0' }, json: async () => ({}) };
      return { ok: true, status: 200, json: async () => ({ candidates: [{ content: { parts: [{ text: 'ok' }] } }] }) };
    };
    assert.equal(await gemini.generateText({ system: 's', prompt: 'p' }), 'ok');
    assert.equal(calls, 3);
  } finally {
    global.fetch = originalFetch;
    if (originalKey == null) delete process.env.GEMINI_API_KEY; else process.env.GEMINI_API_KEY = originalKey;
    if (originalBase == null) delete process.env.GEMINI_RETRY_BASE_MS; else process.env.GEMINI_RETRY_BASE_MS = originalBase;
  }
});

test('does not retry non-transient Gemini 4xx failures', async () => {
  const originalFetch = global.fetch;
  const originalKey = process.env.GEMINI_API_KEY;
  process.env.GEMINI_API_KEY = 'unit-test-key';
  let calls = 0;
  try {
    global.fetch = async () => { calls += 1; return { ok: false, status: 400, json: async () => ({}) }; };
    await assert.rejects(gemini.generateText({ system: 's', prompt: 'p' }), /status 400/);
    assert.equal(calls, 1);
  } finally {
    global.fetch = originalFetch;
    if (originalKey == null) delete process.env.GEMINI_API_KEY; else process.env.GEMINI_API_KEY = originalKey;
  }
});

test('rejects malformed, empty, network, and timeout responses', async () => {
  const originalFetch = global.fetch;
  const originalWarn = console.warn;
  const originalKey = process.env.GEMINI_API_KEY;
  process.env.GEMINI_API_KEY = 'unit-test-key';
  console.warn = () => {};
  try {
    global.fetch = async () => ({ ok: true, status: 200, json: async () => null });
    await assert.rejects(gemini.generateText({ system: 's', prompt: 'p' }), /empty response/);

    global.fetch = async () => {
      throw new Error('socket failed');
    };
    await assert.rejects(gemini.generateText({ system: 's', prompt: 'p' }), /network request failed/);

    global.fetch = async () => {
      const error = new Error('aborted');
      error.name = 'AbortError';
      throw error;
    };
    await assert.rejects(gemini.generateText({ system: 's', prompt: 'p' }), /timed out/);
  } finally {
    global.fetch = originalFetch;
    console.warn = originalWarn;
    if (originalKey == null) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = originalKey;
  }
});
