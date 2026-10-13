const test = require('node:test');
const assert = require('node:assert/strict');
const { createVerifyToken } = require('../middleware/auth');

function response() {
  return { statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
}

test('auth guard rejects missing tokens', async () => {
  const res = response();
  await createVerifyToken({ verifyIdToken: async () => ({ uid: 'x' }) })({ headers: {} }, res, () => {});
  assert.equal(res.statusCode, 401);
});

test('auth guard accepts verified Firebase tokens', async () => {
  const req = { headers: { authorization: 'Bearer valid-token' } };
  const res = response();
  let nextCalled = false;
  await createVerifyToken({ verifyIdToken: async () => ({ uid: 'user-1' }) })(req, res, () => { nextCalled = true; });
  assert.equal(req.uid, 'user-1');
  assert.equal(nextCalled, true);
});

test('auth guard blocks all authenticated access while deletion is pending', async () => {
  const req = { headers: { authorization: 'Bearer valid-token' } };
  const res = response();
  const db = {
    collection: () => ({
      doc: () => ({
        get: async () => ({ exists: true, data: () => ({ deletionPending: true }) }),
      }),
    }),
  };
  let nextCalled = false;
  await createVerifyToken(
    { verifyIdToken: async () => ({ uid: 'user-1', auth_time: 123 }) },
    db,
  )(req, res, () => { nextCalled = true; });
  assert.equal(nextCalled, false);
  assert.equal(res.statusCode, 403);
  assert.equal(res.body.code, 'ACCOUNT_DELETION_PENDING');
});
