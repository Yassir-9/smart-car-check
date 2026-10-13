const test = require('node:test');
const assert = require('node:assert/strict');
const { createAccountStatusGuard } = require('../middleware/accountStatus');

function mockResponse() {
  return {
    statusCode: 200,
    body: null,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
}

function mockDb({ pending = false, fail = false } = {}) {
  return {
    collection(name) {
      assert.equal(name, 'users');
      return {
        doc(uid) {
          assert.equal(uid, 'user-123');
          return {
            async get() {
              if (fail) throw new Error('Firestore unavailable');
              return {
                exists: true,
                data: () => ({ deletionPending: pending }),
              };
            },
          };
        },
      };
    },
  };
}

test('allows an active account', async () => {
  const res = mockResponse();
  let allowed = false;
  await createAccountStatusGuard(mockDb())(
    { uid: 'user-123' }, res, () => { allowed = true; }
  );
  assert.equal(allowed, true);
  assert.equal(res.statusCode, 200);
});

test('blocks an account pending deletion', async () => {
  const res = mockResponse();
  let allowed = false;
  await createAccountStatusGuard(mockDb({ pending: true }))(
    { uid: 'user-123' }, res, () => { allowed = true; }
  );
  assert.equal(allowed, false);
  assert.equal(res.statusCode, 403);
  assert.equal(res.body.error, 'ACCOUNT_DELETION_PENDING');
});

test('rejects requests without a verified user ID', async () => {
  const res = mockResponse();
  await createAccountStatusGuard(mockDb())(
    {}, res, () => { throw new Error('Must not continue'); }
  );
  assert.equal(res.statusCode, 401);
});

test('fails closed when Firestore is unavailable', async () => {
  const res = mockResponse();
  await createAccountStatusGuard(mockDb({ fail: true }))(
    { uid: 'user-123' }, res, () => { throw new Error('Must not continue'); }
  );
  assert.equal(res.statusCode, 503);
  assert.equal(res.body.error, 'ACCOUNT_STATUS_UNAVAILABLE');
});
