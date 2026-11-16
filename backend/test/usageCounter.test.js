const test = require('node:test');
const assert = require('node:assert/strict');
const { reserveUsage, releaseUsage, monthKey, DIAGNOSIS_FIELD } = require('../services/usage/usageCounter');

// Minimal Firestore fake with OPTIMISTIC transactions like the real thing: a
// transaction commits only if the documents it read were not changed meanwhile,
// otherwise the callback is retried. `yieldMs` interleaves concurrent requests.
function fakeDb(initial = {}, { yieldMs = 2 } = {}) {
  const docs = new Map(Object.entries(initial).map(([path, data]) => [path, { data, version: 1 }]));
  const refFor = (path) => ({ path });
  const wait = () => new Promise((resolve) => setTimeout(resolve, yieldMs));
  const db = {
    docs,
    collection: (c) => ({ doc: (d) => ({ collection: (sub) => ({ doc: (id) => refFor(`${c}/${d}/${sub}/${id}`) }) }) }),
    async runTransaction(fn) {
      for (let attempt = 0; attempt < 50; attempt += 1) {
        const reads = new Map();
        const writes = [];
        const tx = {
          async get(ref) {
            await wait();
            const entry = docs.get(ref.path);
            reads.set(ref.path, entry ? entry.version : 0);
            return { exists: !!entry, data: () => (entry ? { ...entry.data } : undefined) };
          },
          set(ref, data, options) { writes.push({ ref, data, merge: options?.merge }); },
        };
        const result = await fn(tx);
        await wait();
        const conflict = [...reads].some(([path, version]) => (docs.get(path)?.version || 0) !== version);
        if (conflict) continue;
        for (const { ref, data, merge } of writes) {
          const entry = docs.get(ref.path);
          docs.set(ref.path, { data: merge && entry ? { ...entry.data, ...data } : { ...data }, version: (entry?.version || 0) + 1 });
        }
        return result;
      }
      throw new Error('transaction kept conflicting');
    },
  };
  return db;
}

const path = (uid, now = new Date()) => `users/${uid}/usage/${monthKey(now)}`;

test('20 parallel requests with limit 7 allow exactly 7 and the counter ends at 7', async () => {
  const db = fakeDb();
  const results = await Promise.all(Array.from({ length: 20 }, () => reserveUsage(db, 'u1', DIAGNOSIS_FIELD, 7)));
  assert.equal(results.filter((r) => r.allowed).length, 7);
  assert.equal(results.filter((r) => !r.allowed).length, 13);
  assert.equal(db.docs.get(path('u1')).data[DIAGNOSIS_FIELD], 7);
});

test('control: a non-transactional read-then-write DOES exceed the limit under the same fake', async () => {
  const db = fakeDb();
  const ref = db.collection('users').doc('u1').collection('usage').doc(monthKey());
  const naive = async () => {
    await new Promise((r) => setTimeout(r, 2));
    const entry = db.docs.get(ref.path);
    const count = entry ? entry.data[DIAGNOSIS_FIELD] || 0 : 0;
    if (count >= 7) return false;
    await new Promise((r) => setTimeout(r, 2));
    db.docs.set(ref.path, { data: { [DIAGNOSIS_FIELD]: count + 1 }, version: 1 });
    return true;
  };
  const allowed = (await Promise.all(Array.from({ length: 20 }, naive))).filter(Boolean).length;
  assert.ok(allowed > 7, `naive version allowed ${allowed}`);
});

test('a counter already at the limit refuses without changing it', async () => {
  const db = fakeDb({ [path('u2')]: { [DIAGNOSIS_FIELD]: 7 } });
  const r = await reserveUsage(db, 'u2', DIAGNOSIS_FIELD, 7);
  assert.equal(r.allowed, false);
  assert.equal(r.count, 7);
  assert.equal(db.docs.get(path('u2')).data[DIAGNOSIS_FIELD], 7);
});

test('a failed request gives its slot back (failed attempts are not counted)', async () => {
  const db = fakeDb();
  const reservation = await reserveUsage(db, 'u3', DIAGNOSIS_FIELD, 7);
  assert.equal(db.docs.get(path('u3')).data[DIAGNOSIS_FIELD], 1);
  await releaseUsage(db, reservation);
  assert.equal(db.docs.get(path('u3')).data[DIAGNOSIS_FIELD], 0);
  // never below zero, and a refused reservation is a no-op
  await releaseUsage(db, reservation);
  assert.equal(db.docs.get(path('u3')).data[DIAGNOSIS_FIELD], 0);
  await releaseUsage(db, { allowed: false });
});

test('released slots can be reused by parallel requests without exceeding the limit', async () => {
  const db = fakeDb();
  const first = await Promise.all(Array.from({ length: 7 }, () => reserveUsage(db, 'u4', DIAGNOSIS_FIELD, 7)));
  await Promise.all(first.slice(0, 3).map((r) => releaseUsage(db, r)));
  const next = await Promise.all(Array.from({ length: 10 }, () => reserveUsage(db, 'u4', DIAGNOSIS_FIELD, 7)));
  assert.equal(next.filter((r) => r.allowed).length, 3);
  assert.equal(db.docs.get(path('u4')).data[DIAGNOSIS_FIELD], 7);
});

test('counters are per field and per user (diagnoses and quote reviews are separate)', async () => {
  const db = fakeDb();
  await reserveUsage(db, 'u5', DIAGNOSIS_FIELD, 7);
  const review = await reserveUsage(db, 'u5', 'repairReviewCount', 7);
  assert.equal(review.count, 1);
  const other = await reserveUsage(db, 'u6', DIAGNOSIS_FIELD, 7);
  assert.equal(other.count, 1);
  assert.deepEqual(db.docs.get(path('u5')).data, { diagnosisCount: 1, repairReviewCount: 1 });
});
