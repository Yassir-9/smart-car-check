const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const helmet = require('helmet');
const { createLimiter, clientKey } = require('../middleware/rateLimit');
const { createCorsOptions, helmetOptions } = require('../middleware/httpSecurity');
const { requireAdminSecret } = require('../middleware/adminAuth');

function response() {
  return {
    statusCode: 200,
    body: null,
    status(code) { this.statusCode = code; return this; },
    send(body) { this.body = body; return this; },
  };
}

async function withServer(app, callback) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    return await callback(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

test('rate limiter keys authenticated requests by verified uid', () => {
  assert.equal(clientKey({ uid: 'user-1', ip: '203.0.113.1' }), 'uid:user-1');
  assert.notEqual(
    clientKey({ uid: 'user-1', ip: '203.0.113.1' }),
    clientKey({ uid: 'user-2', ip: '203.0.113.1' }),
  );
});

test('rate limiter returns a safe 429 response after the configured limit', async () => {
  const app = express();
  app.set('trust proxy', 1);
  app.use((req, _res, next) => { req.uid = req.get('x-test-uid'); next(); });
  app.get('/limited', createLimiter({ windowMs: 60_000, limit: 2 }), (_req, res) => res.json({ ok: true }));
  await withServer(app, async (baseUrl) => {
    const options = { headers: { 'x-test-uid': 'qa-user' } };
    assert.equal((await fetch(`${baseUrl}/limited`, options)).status, 200);
    assert.equal((await fetch(`${baseUrl}/limited`, options)).status, 200);
    const limited = await fetch(`${baseUrl}/limited`, options);
    assert.equal(limited.status, 429);
    const body = await limited.json();
    assert.equal(body.code, 'RATE_LIMITED');
    assert.equal(Object.hasOwn(body, 'stack'), false);
  });
});

test('CORS allows the deployed Flutter Web origin and rejects unknown origins', async () => {
  const { options } = createCorsOptions('https://app.example.com');
  await new Promise((resolve, reject) => options.origin('https://yassir-9.github.io', (error, allowed) => {
    try { assert.ifError(error); assert.equal(allowed, true); resolve(); } catch (cause) { reject(cause); }
  }));
  await new Promise((resolve, reject) => options.origin('https://evil.example', (error) => {
    try { assert.equal(error?.statusCode, 403); resolve(); } catch (cause) { reject(cause); }
  }));
});

test('Helmet sets security headers and removes Express disclosure', async () => {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet(helmetOptions));
  app.get('/', (_req, res) => res.send('ok'));
  await withServer(app, async (baseUrl) => {
    const result = await fetch(baseUrl);
    assert.equal(result.headers.get('x-powered-by'), null);
    assert.equal(result.headers.get('x-content-type-options'), 'nosniff');
    assert.equal(result.headers.get('x-frame-options'), 'SAMEORIGIN');
  });
});

test('admin secret guard fails closed and accepts only the exact configured header', () => {
  const previous = process.env.ADMIN_SECRET;
  process.env.ADMIN_SECRET = 'unit-test-admin-secret';
  try {
    for (const supplied of [undefined, 'wrong-secret']) {
      const req = { get: () => supplied };
      const res = response();
      let called = false;
      requireAdminSecret(req, res, () => { called = true; });
      assert.equal(res.statusCode, 401);
      assert.equal(called, false);
    }
    const req = { get: () => 'unit-test-admin-secret' };
    const res = response();
    let called = false;
    requireAdminSecret(req, res, () => { called = true; });
    assert.equal(called, true);
  } finally {
    if (previous === undefined) delete process.env.ADMIN_SECRET;
    else process.env.ADMIN_SECRET = previous;
  }
});
