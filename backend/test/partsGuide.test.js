const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const { createGoRouter } = require('../routes/go');
const { createLimiter } = require('../middleware/rateLimit');
const { parseGuideQuery, buildDestination, affiliateParams } = require('../services/partsGuide/storeRedirect');
const { STORES, enabledStoreKeys } = require('../config/partnerStores');
const { isPartsGuideEnabled, isExternalPartSearchEnabled } = require('../config/features');

const passLimiter = (req, res, next) => next();

async function withApp(env, fn, limiter = passLimiter) {
  const app = express();
  app.use('/go', createGoRouter({ limiter, env }));
  const server = http.createServer(app);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  try { return await fn(`http://127.0.0.1:${server.address().port}`); }
  finally { await new Promise((r) => server.close(r)); }
}
const get = (url, headers = {}) => fetch(url, { redirect: 'manual', headers });
const ON = { PARTS_GUIDE_ENABLED: 'true' };
const q = (o) => new URLSearchParams(o).toString();

test('flags are off by default', () => {
  assert.equal(isPartsGuideEnabled({}), false);
  assert.equal(isExternalPartSearchEnabled({}), false);
  assert.equal(isPartsGuideEnabled({ PARTS_GUIDE_ENABLED: 'true' }), true);
});

test('disabled flag: /go/* answers 404 and never redirects', () => withApp({}, async (base) => {
  for (const path of ['/go/speero?part=filter', '/go/stores', '/go/web?part=filter']) {
    const res = await get(base + path);
    assert.equal(res.status, 404, path);
    assert.equal(res.headers.get('location'), null);
  }
}));

test('speero redirects to its verified search URL built from part/make/model/year only', () => withApp(ON, async (base) => {
  const res = await get(`${base}/go/speero?${q({ part: 'oil filter', make: 'Toyota', model: 'Camry', year: '2020' })}`);
  assert.equal(res.status, 302);
  const location = new URL(res.headers.get('location'));
  assert.equal(location.origin, 'https://speero.net');
  assert.equal(location.pathname, '/search');
  assert.equal(location.searchParams.get('q'), 'Toyota Camry 2020 oil filter');
  assert.equal(res.headers.get('cache-control'), 'no-store');
  assert.equal(res.headers.get('referrer-policy'), 'no-referrer');
}));

test('web store is a Google search restricted to the enabled partner sites', () => withApp(ON, async (base) => {
  const res = await get(`${base}/go/web?part=brake+pads`);
  assert.equal(res.status, 302);
  const location = new URL(res.headers.get('location'));
  assert.equal(location.hostname, 'www.google.com');
  assert.equal(location.searchParams.get('q'), 'brake pads (site:speero.net)');
}));

test('open redirect is impossible: unknown stores, full URLs and extra parameters are refused', () => withApp(ON, async (base) => {
  for (const path of [
    '/go/evil.com?part=x', '/go/https%3A%2F%2Fevil.com?part=x', '/go/..%2F..%2Fevil?part=x', '/go/__proto__?part=x', '/go/constructor?part=x',
  ]) {
    const res = await get(base + path);
    assert.equal(res.status, 404, path);
    assert.equal(res.headers.get('location'), null);
  }
  for (const extra of ['url=https://evil.com', 'redirect=https://evil.com', 'next=/x', 'store=evil.com']) {
    const res = await get(`${base}/go/speero?part=x&${extra}`);
    assert.equal(res.status, 400, extra);
    assert.equal((await res.json()).code, 'UNKNOWN_PARAMETER');
  }
  for (const part of ['https://evil.com', 'http://evil.com/x', '//evil.com', 'www.evil.com', 'ftp://x']) {
    const res = await get(`${base}/go/speero?${q({ part })}`);
    assert.equal(res.status, 400, part);
    assert.equal((await res.json()).code, 'URL_NOT_ALLOWED');
  }
  // arrays/objects in the query string
  assert.equal((await get(`${base}/go/speero?part=a&part=b`)).status, 400);
  assert.equal((await get(`${base}/go/speero?part[x]=b`)).status, 400);
}));

test('a VIN is refused (17 chars, no I/O/Q), in any field', () => withApp(ON, async (base) => {
  const vin = '1HGCM82633A004352';
  for (const field of ['part', 'make', 'model']) {
    const res = await get(`${base}/go/speero?${q({ part: 'filter', [field]: `${field === 'part' ? '' : ''}${vin}` })}`);
    assert.equal(res.status, 400, field);
    assert.equal((await res.json()).code, 'IDENTIFIER_NOT_ALLOWED');
  }
  assert.equal((await get(`${base}/go/speero?${q({ part: `filter ${vin.toLowerCase()} x` })}`)).status, 400);
  // a normal 16-character part number is fine
  assert.equal((await get(`${base}/go/speero?${q({ part: '04152-YZZA1-0000' })}`)).status, 302);
}));

test('fields longer than 80 characters, control characters and bad years are refused', () => withApp(ON, async (base) => {
  const long = 'a'.repeat(81);
  assert.equal((await get(`${base}/go/speero?${q({ part: long })}`)).status, 400);
  assert.equal((await get(`${base}/go/speero?${q({ part: 'a'.repeat(80) })}`)).status, 302);
  assert.equal((await get(`${base}/go/speero?part=a%00b`)).status, 400);
  assert.equal((await get(`${base}/go/speero?part=a%0Ab`)).status, 400);
  assert.equal((await get(`${base}/go/speero?part=x&year=1900`)).status, 400);
  assert.equal((await get(`${base}/go/speero?part=x&year=20x0`)).status, 400);
  assert.equal((await get(`${base}/go/speero`)).status, 400);
}));

test('no user identity is read: headers, cookies and tokens never reach the destination', () => withApp(ON, async (base) => {
  const res = await get(`${base}/go/speero?part=filter`, {
    authorization: 'Bearer secret-token-123', cookie: 'session=abc', 'x-user-id': 'uid-42',
  });
  assert.equal(res.status, 302);
  const location = res.headers.get('location');
  assert.doesNotMatch(location, /secret-token|session=|uid-42/);
  assert.equal(new URL(location).searchParams.get('q'), 'filter');
  // and the route does not even accept a uid-like parameter
  assert.equal((await get(`${base}/go/speero?part=x&uid=1`)).status, 400);
}));

test('affiliate IDs come from env, are appended safely, and plain links work when empty', () => {
  const none = buildDestination('speero', 'filter', {});
  assert.equal(new URL(none.url).search, '?q=filter');
  const aff = buildDestination('speero', 'filter', { PARTNER_STORES_ENABLED: 'speero', AFFILIATE_SPEERO: 'ref=abc123&utm_source=smartcar' });
  const u = new URL(aff.url);
  assert.equal(u.searchParams.get('ref'), 'abc123');
  assert.equal(u.searchParams.get('utm_source'), 'smartcar');
  assert.equal(u.searchParams.get('q'), 'filter');
  // cannot override q, junk is ignored
  assert.equal(new URL(buildDestination('speero', 'filter', { AFFILIATE_SPEERO: 'q=evil' }).url).searchParams.get('q'), 'filter');
  assert.deepEqual(affiliateParams(STORES.speero, { AFFILIATE_SPEERO: 'bad key=1&ok=2&=3&x=' }), [['ok', '2']]);
  assert.deepEqual(affiliateParams(STORES.speero, { AFFILIATE_SPEERO: 'x'.repeat(300) }), []);
  assert.deepEqual(affiliateParams(STORES.web, { AFFILIATE_WEB: 'a=b' }), []);
  // the destination host never changes whatever the affiliate value is
  assert.equal(new URL(buildDestination('speero', 'f', { AFFILIATE_SPEERO: 'ref=https://evil.com' }).url).hostname, 'speero.net');
});

test('Odiggo, Noon and Amazon.sa are ready but disabled; enabling one opens its home page without a query', () => {
  assert.deepEqual(enabledStoreKeys({}).sort(), ['speero', 'web']);
  for (const key of ['odiggo', 'noon', 'amazon']) {
    assert.equal(STORES[key].enabledByDefault, false);
    assert.equal(STORES[key].searchUrl, null);
    assert.equal(buildDestination(key, 'filter', {}).code, 'STORE_DISABLED');
  }
  const on = buildDestination('noon', 'private text', { PARTNER_STORES_ENABLED: 'noon' });
  assert.equal(on.url, 'https://www.noon.com/');
  assert.equal(buildDestination('amazon', 'x', { PARTNER_STORES_ENABLED: 'amazon' }).url, 'https://www.amazon.sa/');
  assert.equal(buildDestination('odiggo', 'x', { PARTNER_STORES_ENABLED: 'odiggo' }).url, 'https://odiggo.com/');
  assert.equal(buildDestination('speero', 'x', { PARTNER_STORES_ENABLED: 'noon' }).code, 'STORE_DISABLED');
});

test('/go/stores lists only enabled stores (key and name, nothing else)', () => withApp(ON, async (base) => {
  const body = await (await get(`${base}/go/stores`)).json();
  assert.deepEqual(body.stores.map((s) => s.key).sort(), ['speero', 'web']);
  assert.deepEqual(Object.keys(body.stores[0]).sort(), ['key', 'name']);
}));

test('the redirector is rate limited per IP', () => withApp(ON, async (base) => {
  const limiter = createLimiter({ windowMs: 60000, limit: 3 });
  await withApp(ON, async (limitedBase) => {
    const codes = [];
    for (let i = 0; i < 5; i += 1) codes.push((await get(`${limitedBase}/go/speero?part=x`)).status);
    assert.deepEqual(codes, [302, 302, 302, 429, 429]);
  }, limiter);
  const { partsGuideLimiter } = require('../middleware/rateLimit');
  assert.equal(typeof partsGuideLimiter, 'function');
}));

test('parseGuideQuery composes make model year part in that order', () => {
  assert.deepEqual(parseGuideQuery({ part: 'pads', make: 'Nissan', model: 'Sunny', year: '2018' }), { ok: true, q: 'Nissan Sunny 2018 pads' });
  assert.deepEqual(parseGuideQuery({ part: ' pads ' }), { ok: true, q: 'pads' });
});
