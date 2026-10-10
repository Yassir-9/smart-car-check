const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const { createPartsRouter } = require('../routes/createPartsRouter');
const { createLimiter, contactIpKey } = require('../middleware/rateLimit');
const { localizedError } = require('../utils/localizedResponse');
const { sanitize } = require('../utils/logger');
const {
  toBuyerOrder,
  toSellerOrder,
  sanitizeDiagnosisHistoryEntry,
} = require('../services/marketplace/partPrivacy');

const records = {
  'part-1': {
    ownerId: 'user-1',
    partName: 'Brake pad',
    carBrand: 'Nissan',
    carModel: 'Maxima',
    price: '120',
    sellerPhone: '0500000000',
    notes: 'Front axle',
    createdAt: '2026-10-09T10:00:00.000Z',
    privateContactEmail: 'hidden@example.com',
    internalModerationNote: 'private',
  },
  'part-2': {
    ownerId: 'user-2',
    partName: 'Filter',
    carBrand: 'Toyota',
    carModel: 'Camry',
    sellerPhone: '0511111111',
    createdAt: '2026-10-08T10:00:00.000Z',
  },
};

function snapshot(entries) {
  return {
    docs: entries.map(([id, data]) => ({ id, data: () => ({ ...data }) })),
  };
}

function fakeDb() {
  return {
    collection(name) {
      assert.equal(name, 'parts');
      return {
        orderBy() {
          return { get: async () => snapshot(Object.entries(records)) };
        },
        where(field, operation, value) {
          assert.equal(field, 'ownerId');
          assert.equal(operation, '==');
          return {
            get: async () => snapshot(
              Object.entries(records).filter(([, data]) => data.ownerId === value),
            ),
          };
        },
        doc(id) {
          return {
            id,
            get: async () => ({
              id,
              exists: Object.hasOwn(records, id),
              data: () => ({ ...records[id] }),
            }),
            set: async () => {},
            delete: async () => {},
          };
        },
        add: async () => ({ id: 'new-part' }),
      };
    },
  };
}

function verifyToken(req, res, next) {
  const token = req.get('authorization');
  if (!token?.startsWith('Bearer user-')) {
    return res.status(401).json({ code: 'AUTH_REQUIRED', error: 'Sign in required' });
  }
  req.uid = token.slice('Bearer '.length);
  return next();
}

const pass = (_req, _res, next) => next();
const logger = { error() {} };

function appWith({ uidLimiter = pass, ipLimiter = pass, exposePublicContact = false } = {}) {
  const app = express();
  app.set('trust proxy', 1);
  app.use(express.json());
  app.use(createPartsRouter({
    db: fakeDb(),
    verifyToken,
    marketplaceReadLimiter: pass,
    marketplaceWriteLimiter: pass,
    contactUidDailyLimiter: uidLimiter,
    contactIpDailyLimiter: ipLimiter,
    localizedError,
    logger,
    exposePublicContact,
  }));
  return app;
}

async function withServer(app, callback) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    return await callback(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (
      error ? reject(error) : resolve()
    )));
  }
}

test('public parts use an allowlist and never expose contact or private fields', async () => {
  await withServer(appWith(), async (baseUrl) => {
    const response = await fetch(`${baseUrl}/parts`);
    assert.equal(response.status, 200);
    const parts = await response.json();
    assert.equal(parts.length, 2);
    for (const part of parts) {
      assert.equal(Object.hasOwn(part, 'sellerPhone'), false);
      assert.equal(Object.hasOwn(part, 'privateContactEmail'), false);
      assert.equal(Object.hasOwn(part, 'internalModerationNote'), false);
    }
    assert.deepEqual(
      Object.keys(parts[0]).sort(),
      ['carBrand', 'carModel', 'createdAt', 'id', 'notes', 'ownerId', 'partName', 'price'].sort(),
    );
  });
});

test('compatibility rollout keeps legacy public contact until the web client is live', async () => {
  await withServer(appWith({ exposePublicContact: true }), async (baseUrl) => {
    const parts = await (await fetch(`${baseUrl}/parts`)).json();
    assert.equal(parts[0].sellerPhone, '0500000000');
    assert.equal(Object.hasOwn(parts[0], 'privateContactEmail'), false);
  });
});

test('mine is ordered before dynamic routes, requires auth, and returns only the owner records', async () => {
  await withServer(appWith(), async (baseUrl) => {
    assert.equal((await fetch(`${baseUrl}/parts/mine`)).status, 401);
    const response = await fetch(`${baseUrl}/parts/mine`, {
      headers: { authorization: 'Bearer user-1' },
    });
    assert.equal(response.status, 200);
    const parts = await response.json();
    assert.equal(parts.length, 1);
    assert.equal(parts[0].id, 'part-1');
    assert.equal(parts[0].ownerId, 'user-1');
    assert.equal(parts[0].sellerPhone, '0500000000');
  });
});

test('contact requires auth and returns contact only after an explicit authenticated request', async () => {
  await withServer(appWith(), async (baseUrl) => {
    assert.equal((await fetch(`${baseUrl}/parts/part-1/contact`)).status, 401);
    const response = await fetch(`${baseUrl}/parts/part-1/contact`, {
      headers: { authorization: 'Bearer user-2' },
    });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { sellerPhone: '0500000000' });
    const missing = await fetch(`${baseUrl}/parts/missing/contact`, {
      headers: { authorization: 'Bearer user-2' },
    });
    assert.equal(missing.status, 404);
  });
});

test('private owner data rejects another authenticated user with 403', async () => {
  await withServer(appWith(), async (baseUrl) => {
    const forbidden = await fetch(`${baseUrl}/parts/part-1/private`, {
      headers: { authorization: 'Bearer user-2' },
    });
    assert.equal(forbidden.status, 403);
    const owner = await fetch(`${baseUrl}/parts/part-1/private`, {
      headers: { authorization: 'Bearer user-1' },
    });
    assert.equal(owner.status, 200);
    assert.equal((await owner.json()).sellerPhone, '0500000000');
  });
});

test('update and delete reject an authenticated non-owner with 403', async () => {
  await withServer(appWith(), async (baseUrl) => {
    const headers = {
      authorization: 'Bearer user-2',
      'content-type': 'application/json',
    };
    const update = await fetch(`${baseUrl}/parts/part-1`, {
      method: 'PUT',
      headers,
      body: JSON.stringify({
        partName: 'Changed',
        carBrand: 'Nissan',
        sellerPhone: '0599999999',
      }),
    });
    assert.equal(update.status, 403);

    const remove = await fetch(`${baseUrl}/parts/part-1`, {
      method: 'DELETE',
      headers: { authorization: 'Bearer user-2' },
    });
    assert.equal(remove.status, 403);
  });
});

test('contact endpoint returns a safe 429 when the per-UID daily budget is exhausted', async () => {
  const uidLimiter = createLimiter({
    windowMs: 24 * 60 * 60 * 1000,
    limit: 1,
    keyGenerator: (req) => `test-contact:${req.uid}`,
  });
  await withServer(appWith({ uidLimiter }), async (baseUrl) => {
    const options = { headers: { authorization: 'Bearer user-2' } };
    assert.equal((await fetch(`${baseUrl}/parts/part-1/contact`, options)).status, 200);
    const limited = await fetch(`${baseUrl}/parts/part-1/contact`, options);
    assert.equal(limited.status, 429);
    assert.equal((await limited.json()).code, 'RATE_LIMITED');
  });
});

test('contact endpoint also enforces a separate per-IP daily budget', async () => {
  const ipLimiter = createLimiter({
    windowMs: 24 * 60 * 60 * 1000,
    limit: 1,
    keyGenerator: contactIpKey,
  });
  await withServer(appWith({ ipLimiter }), async (baseUrl) => {
    const first = await fetch(`${baseUrl}/parts/part-1/contact`, {
      headers: { authorization: 'Bearer user-1' },
    });
    assert.equal(first.status, 200);
    const limited = await fetch(`${baseUrl}/parts/part-2/contact`, {
      headers: { authorization: 'Bearer user-2' },
    });
    assert.equal(limited.status, 429);
    assert.equal((await limited.json()).code, 'RATE_LIMITED');
  });
});

test('logger sanitizer redacts contact fields', () => {
  const sanitized = sanitize({ sellerPhone: '0500000000', nested: { contact: 'secret' } });
  assert.equal(sanitized.sellerPhone, '[redacted]');
  assert.equal(sanitized.nested.contact, '[redacted]');
});

test('buyer and seller order DTOs do not expose contact data or other sellers items', () => {
  const order = {
    status: 'paid',
    totalAmount: 240,
    createdAt: '2026-10-09T10:00:00.000Z',
    items: [
      { partId: 'part-1', sellerId: 'user-1', sellerPhone: '0500000000' },
      { partId: 'part-2', sellerId: 'user-2', sellerPhone: '0511111111' },
    ],
  };
  const buyer = toBuyerOrder('order-1', order);
  assert.equal(buyer.items.length, 2);
  assert.equal(buyer.items.some((item) => Object.hasOwn(item, 'sellerPhone')), false);

  const seller = toSellerOrder('order-1', order, 'user-1');
  assert.deepEqual(seller.items.map((item) => item.partId), ['part-1']);
  assert.equal(Object.hasOwn(seller.items[0], 'sellerPhone'), false);
});

test('legacy diagnosis history is sanitized before it is returned', () => {
  const entry = {
    id: 'diagnosis-1',
    result: {
      matched_parts: [{
        id: 'part-1',
        partName: 'Brake pad',
        sellerPhone: '0500000000',
        privateContactEmail: 'hidden@example.com',
      }],
    },
  };
  const sanitized = sanitizeDiagnosisHistoryEntry(entry);
  assert.equal(sanitized.result.matched_parts[0].partName, 'Brake pad');
  assert.equal(Object.hasOwn(sanitized.result.matched_parts[0], 'sellerPhone'), false);
  assert.equal(Object.hasOwn(sanitized.result.matched_parts[0], 'privateContactEmail'), false);
});
