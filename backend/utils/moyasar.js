const logger = require('./logger');

const MOYASAR_BASE = 'https://api.moyasar.com/v1';

function authHeader() {
  const key = process.env.MOYASAR_SECRET_KEY;
  if (!key) throw new Error('MOYASAR_SECRET_KEY is not configured');
  return `Basic ${Buffer.from(`${key}:`).toString('base64')}`;
}

async function fetchVerifiedInvoice(invoiceId, fetchImpl = fetch) {
  if (!invoiceId || typeof invoiceId !== 'string') return null;
  const response = await fetchImpl(`${MOYASAR_BASE}/invoices/${encodeURIComponent(invoiceId)}`, {
    headers: { Authorization: authHeader() },
  });
  if (!response.ok) {
    logger.warn('Moyasar invoice verification failed', { invoiceId, statusCode: response.status });
    return null;
  }
  return response.json();
}

module.exports = { MOYASAR_BASE, authHeader, fetchVerifiedInvoice };
