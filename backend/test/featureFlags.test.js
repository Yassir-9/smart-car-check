const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const express = require('express');
const { isSubscriptionsEnabled, isMarketplaceWritesEnabled, requireFeature } = require('../config/features');
const { localizedError } = require('../utils/localizedResponse');

test('feature flags default to disabled and only accept "true"', () => {
  assert.equal(isSubscriptionsEnabled({}), false);
  assert.equal(isMarketplaceWritesEnabled({}), false);
  assert.equal(isSubscriptionsEnabled({ SUBSCRIPTIONS_ENABLED: '1' }), false);
  assert.equal(isSubscriptionsEnabled({ SUBSCRIPTIONS_ENABLED: ' TRUE ' }), true);
  assert.equal(isMarketplaceWritesEnabled({ MARKETPLACE_WRITES_ENABLED: 'true' }), true);
});

async function call(enabled, locale) {
  const app = express();
  app.use(express.json());
  app.post('/x', requireFeature(() => enabled, localizedError), (req, res) => res.json({ ok: true }));
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const res = await fetch(`http://127.0.0.1:${port}/x`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-App-Locale': locale },
      body: '{}',
    });
    return { status: res.status, body: await res.json() };
  } finally {
    server.close();
  }
}

test('disabled feature answers 403 FEATURE_DISABLED in both languages', async () => {
  const en = await call(false, 'en');
  assert.equal(en.status, 403);
  assert.equal(en.body.code, 'FEATURE_DISABLED');
  assert.match(en.body.error, /not available/i);
  const ar = await call(false, 'ar');
  assert.equal(ar.status, 403);
  assert.equal(ar.body.code, 'FEATURE_DISABLED');
});

test('enabled feature passes through', async () => {
  assert.deepEqual((await call(true, 'en')).body, { ok: true });
});

test('payment-creating subscription route is behind the flag', () => {
  const src = fs.readFileSync(path.join(__dirname, '..', 'routes', 'subscription.js'), 'utf8');
  assert.match(src, /router\.post\('\/subscribe', verifyToken, requireFeature\(\(\) => isSubscriptionsEnabled\(\)/);
});

test('order checkout and seller rating writes are behind the marketplace flag', () => {
  const read = (f) => fs.readFileSync(path.join(__dirname, '..', 'routes', f), 'utf8');
  assert.match(read('orders.js'), /router\.post\('\/orders\/checkout', verifyToken, requireFeature\(\(\) => isMarketplaceWritesEnabled\(\)/);
  assert.match(read('ratings.js'), /router\.post\('\/sellers\/:id\/rating', verifyToken, requireFeature\(\(\) => isMarketplaceWritesEnabled\(\)/);
});

test('diagnosis skips the parts collection read when the marketplace is off', () => {
  const src = fs.readFileSync(path.join(__dirname, '..', 'routes', 'diagnosis.js'), 'utf8');
  assert.match(src, /if \(isMarketplaceWritesEnabled\(\)\) \{\s*parsed\.matched_parts = await findMatchingParts/);
});
