const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { createAccountRouter } = require('../routes/createAccountRouter');

async function withServer(router, action) {
  const app = express();
  app.use(express.json());
  app.use('/api', router);
  const server = await new Promise((resolve) => {
    const instance = app.listen(0, '127.0.0.1', () => resolve(instance));
  });
  try {
    return await action(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('account deletion endpoint rejects unauthenticated requests', async () => {
  const router = createAccountRouter({
    authClient: { verifyIdToken: async () => ({ uid: 'verified-user' }) },
    deletionService: { requestDeletion: async () => ({ status: 'completed' }) },
  });
  await withServer(router, async (base) => {
    const response = await fetch(`${base}/api/account/delete`, { method: 'POST' });
    assert.equal(response.status, 401);
  });
});

test('account deletion always uses token uid and ignores a supplied different uid', async () => {
  let input;
  const router = createAccountRouter({
    authClient: {
      verifyIdToken: async () => ({ uid: 'verified-user', auth_time: 123456 }),
    },
    deletionService: {
      async requestDeletion(value) {
        input = value;
        return { status: 'completed' };
      },
    },
  });
  await withServer(router, async (base) => {
    const response = await fetch(`${base}/api/account/delete`, {
      method: 'POST',
      headers: { authorization: 'Bearer valid', 'content-type': 'application/json' },
      body: JSON.stringify({ uid: 'victim-user' }),
    });
    assert.equal(response.status, 200);
    assert.deepEqual(input, { uid: 'verified-user', authTime: 123456 });
  });
});
