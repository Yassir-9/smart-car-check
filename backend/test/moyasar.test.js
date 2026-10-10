const test = require('node:test');
const assert = require('node:assert/strict');
const { fetchVerifiedInvoice } = require('../utils/moyasar');

test('fetches invoice server-side without a real network call', async () => {
  const previous = process.env.MOYASAR_SECRET_KEY;
  process.env.MOYASAR_SECRET_KEY = 'test-only-not-a-real-key';
  let requestedUrl;
  const invoice = await fetchVerifiedInvoice('invoice-1', async (url, options) => {
    requestedUrl = url;
    assert.match(options.headers.Authorization, /^Basic /);
    return { ok: true, json: async () => ({ id: 'invoice-1', status: 'paid', amount: 1499, currency: 'SAR' }) };
  });
  assert.match(requestedUrl, /invoices\/invoice-1$/);
  assert.equal(invoice.status, 'paid');
  if (previous === undefined) delete process.env.MOYASAR_SECRET_KEY;
  else process.env.MOYASAR_SECRET_KEY = previous;
});
