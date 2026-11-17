const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const http = require('node:http');
const express = require('express');

// ---- stubs injected into the require cache (no Firebase, no AI, no network) ----
const abs = (p) => require.resolve(path.join(__dirname, '..', p));
const stub = (p, exports) => { require.cache[abs(p)] = { id: abs(p), filename: abs(p), loaded: true, exports }; };

const store = new Map(); // "users/u/usage/2026-11" -> { data, v }
let reviewMode = 'ok'; // ok | incomplete | throw
const emptySnap = { exists: false, data: () => undefined };
const fakeDb = {
  collection: (c) => ({
    doc: (d = 'auto') => ({
      get: async () => emptySnap,
      set: async () => {},
      collection: (sub) => ({
        doc: (id = 'auto') => ({
          path: `${c}/${d}/${sub}/${id}`,
          get: async () => emptySnap,
          set: async () => {},
        }),
      }),
    }),
  }),
  // Optimistic transactions like Firestore: retry when a document read changed.
  async runTransaction(fn) {
    for (;;) {
      const reads = new Map();
      const writes = [];
      const tx = {
        async get(ref) {
          await new Promise((r) => setTimeout(r, 1));
          const e = store.get(ref.path);
          reads.set(ref.path, e ? e.v : 0);
          return { exists: !!e, data: () => (e ? { ...e.data } : undefined) };
        },
        set(ref, data) { writes.push({ ref, data }); },
      };
      const result = await fn(tx);
      if ([...reads].some(([p, v]) => (store.get(p) ? store.get(p).v : 0) !== v)) continue;
      for (const { ref, data } of writes) {
        const e = store.get(ref.path);
        store.set(ref.path, { data: { ...(e ? e.data : {}), ...data }, v: (e ? e.v : 0) + 1 });
      }
      return result;
    }
  },
};
stub('firebaseAdmin.js', { db: fakeDb });
stub('middleware/auth.js', (req, res, next) => { req.uid = req.get('x-test-uid') || 'u1'; next(); });
const pass = (req, res, next) => next();
stub('middleware/rateLimit.js', { aiLimiter: pass, searchLimiter: pass });
stub('services/ai/aiProvider.js', { getAiProvider: () => ({ name: 'stub', generateJson: async () => '{}' }) });
stub('services/repairReview/repairReviewService.js', {
  generateRepairReview: async () => {
    await new Promise((r) => setTimeout(r, 3));
    if (reviewMode === 'throw') throw new Error('provider down');
    if (reviewMode === 'incomplete') return { analysis_complete: false };
    return { analysis_complete: true, summary: 'ok' };
  },
});

const router = require('../routes/diagnosis');
const app = express();
app.use(express.json());
app.use('/api', router);

async function withServer(fn) {
  const server = http.createServer(app);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  try { return await fn(`http://127.0.0.1:${server.address().port}`); }
  finally { await new Promise((r) => server.close(r)); }
}

function payload(locale) {
  return JSON.stringify({
    workshopStatement: 'change the pads',
    car: { id: 'c1', brand: 'Toyota', model: 'Camry', year: 2020 },
    locale,
  });
}
const call = (base, route, uid = 'u1', locale = 'en') => fetch(`${base}${route}`, {
  method: 'POST',
  headers: { 'content-type': 'application/json', 'x-test-uid': uid },
  body: payload(locale),
});
function usage(uid) {
  const n = new Date();
  const key = `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, '0')}`;
  const e = store.get(`users/${uid}/usage/${key}`);
  return e ? e.data : {};
}

test.beforeEach(() => {
  store.clear();
  reviewMode = 'ok';
  process.env.FREE_MONTHLY_BEFORE_YOU_PAY = '3';
  delete process.env.DEV_BYPASS_USAGE_LIMIT;
});
test.after(() => { delete process.env.FREE_MONTHLY_BEFORE_YOU_PAY; });

test('the 4th quote review in a month is refused with the same 402 shape as the diagnosis limit', () => withServer(async (base) => {
  for (let i = 0; i < 3; i += 1) assert.equal((await call(base, '/api/repair-review')).status, 200);
  const res = await call(base, '/api/before-you-pay'); // alias shares the counter
  assert.equal(res.status, 402);
  const json = await res.json();
  assert.equal(json.code, 'FREE_DIAGNOSIS_LIMIT_REACHED');
  assert.equal(json.subscriptionRequired, false);
  assert.equal(json.freeUsageLimit, 3);
  assert.ok(Date.parse(json.limitResetsAt) > Date.now());
  assert.match(json.error, /free limit for quote reviews/);
  assert.doesNotMatch(json.error, /subscri|pay|اشتراك|دفع/i);
  assert.equal(usage('u1').repairReviewCount, 3);
  assert.equal(usage('u1').diagnosisCount, undefined); // separate from diagnoses
}));

test('the Arabic limit message is returned for locale ar', () => withServer(async (base) => {
  process.env.FREE_MONTHLY_BEFORE_YOU_PAY = '1';
  await call(base, '/api/repair-review');
  const json = await (await call(base, '/api/repair-review', 'u1', 'ar')).json();
  assert.match(json.error, /الحد الشهري المجاني لمراجعة العروض/);
}));

test('10 parallel reviews with a limit of 3 give exactly 3 successes', () => withServer(async (base) => {
  const results = await Promise.all(Array.from({ length: 10 }, () => call(base, '/api/repair-review')));
  const statuses = results.map((r) => r.status);
  assert.equal(statuses.filter((s) => s === 200).length, 3);
  assert.equal(statuses.filter((s) => s === 402).length, 7);
  assert.equal(usage('u1').repairReviewCount, 3);
}));

test('failed or incomplete reviews are not counted', () => withServer(async (base) => {
  reviewMode = 'throw';
  assert.equal((await call(base, '/api/repair-review')).status, 500);
  reviewMode = 'incomplete';
  assert.equal((await call(base, '/api/repair-review')).status, 200);
  assert.equal(usage('u1').repairReviewCount, 0);
  reviewMode = 'ok';
  for (let i = 0; i < 3; i += 1) assert.equal((await call(base, '/api/repair-review')).status, 200);
  assert.equal((await call(base, '/api/repair-review')).status, 402);
}));

test('the limit comes from FREE_MONTHLY_BEFORE_YOU_PAY at request time (default 7 when unset)', () => withServer(async (base) => {
  process.env.FREE_MONTHLY_BEFORE_YOU_PAY = '5';
  for (let i = 0; i < 5; i += 1) assert.equal((await call(base, '/api/repair-review')).status, 200);
  assert.equal((await call(base, '/api/repair-review')).status, 402);
  const { getFreeMonthlyBeforeYouPayLimit } = require('../config/limits');
  assert.equal(getFreeMonthlyBeforeYouPayLimit({}), 7);
  assert.equal(getFreeMonthlyBeforeYouPayLimit({ FREE_MONTHLY_BEFORE_YOU_PAY: 'abc' }), 7);
  assert.equal(getFreeMonthlyBeforeYouPayLimit({ FREE_MONTHLY_BEFORE_YOU_PAY: '12' }), 12);
}));

test('users are counted separately and input errors do not consume a slot', () => withServer(async (base) => {
  process.env.FREE_MONTHLY_BEFORE_YOU_PAY = '1';
  assert.equal((await call(base, '/api/repair-review', 'a')).status, 200);
  assert.equal((await call(base, '/api/repair-review', 'a')).status, 402);
  assert.equal((await call(base, '/api/repair-review', 'b')).status, 200);
  const empty = await fetch(`${base}/api/repair-review`, {
    method: 'POST', headers: { 'content-type': 'application/json', 'x-test-uid': 'c' }, body: '{}',
  });
  assert.equal(empty.status, 400);
  assert.equal(usage('c').repairReviewCount, undefined);
}));

test('/ask-expert is disabled by default (403 FEATURE_DISABLED) and opens only with ASK_EXPERT_ENABLED=true', () => withServer(async (base) => {
  delete process.env.ASK_EXPERT_ENABLED;
  const post = (locale) => fetch(`${base}/api/ask-expert`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-test-uid': 'u1', 'x-app-locale': locale },
    body: JSON.stringify({ question: 'why?', car: { brand: 'Toyota' } }),
  });
  const off = await post('en');
  assert.equal(off.status, 403);
  assert.equal((await off.json()).code, 'FEATURE_DISABLED');
  assert.equal((await post('ar')).status, 403);
  process.env.ASK_EXPERT_ENABLED = 'true';
  try {
    assert.notEqual((await post('en')).status, 403);
  } finally {
    delete process.env.ASK_EXPERT_ENABLED;
  }
}));

test('AI part search routes (/parts/external-search, /obd/part-search) answer 403 FEATURE_DISABLED by default', () => withServer(async (base) => {
  delete process.env.EXTERNAL_PART_SEARCH_ENABLED;
  for (const route of ['/api/parts/external-search', '/api/obd/part-search']) {
    for (const locale of ['en', 'ar']) {
      const res = await fetch(`${base}${route}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-test-uid': 'u1', 'x-app-locale': locale },
        body: JSON.stringify({ query: 'brake pads', car: { brand: 'Toyota' } }),
      });
      assert.equal(res.status, 403, `${route} ${locale}`);
      assert.equal((await res.json()).code, 'FEATURE_DISABLED');
    }
  }
  process.env.EXTERNAL_PART_SEARCH_ENABLED = 'true';
  try {
    const res = await fetch(`${base}/api/parts/external-search`, {
      method: 'POST', headers: { 'content-type': 'application/json', 'x-test-uid': 'u1' }, body: JSON.stringify({}),
    });
    assert.equal(res.status, 400); // passes the gate, then normal validation (query required)
  } finally {
    delete process.env.EXTERNAL_PART_SEARCH_ENABLED;
  }
}));

test('PATCH /history/:id/feedback is disabled by default (403 FEATURE_DISABLED) and opens only with DIAGNOSIS_FEEDBACK_ENABLED=true', () => withServer(async (base) => {
  delete process.env.DIAGNOSIS_FEEDBACK_ENABLED;
  const patch = (locale) => fetch(`${base}/api/history/abc/feedback`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', 'x-test-uid': 'u1', 'x-app-locale': locale },
    body: JSON.stringify({ accurate: true }),
  });
  for (const locale of ['en', 'ar']) {
    const res = await patch(locale);
    assert.equal(res.status, 403, locale);
    assert.equal((await res.json()).code, 'FEATURE_DISABLED');
  }
  process.env.DIAGNOSIS_FEEDBACK_ENABLED = 'true';
  try {
    assert.equal((await patch('en')).status, 404); // passes the gate; the (fake) record does not exist
  } finally {
    delete process.env.DIAGNOSIS_FEEDBACK_ENABLED;
  }
}));
