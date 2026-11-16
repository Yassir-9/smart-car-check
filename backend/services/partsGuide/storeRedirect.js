const { STORES, enabledStoreKeys } = require('../../config/partnerStores');

const ALLOWED_PARAMS = new Set(['part', 'make', 'model', 'year']);
const MAX_FIELD_LENGTH = 80;
const MAX_QUERY_LENGTH = 240;
const CONTROL_CHARS = /[\u0000-\u001F\u007F]/;
const URL_LIKE = /(https?:|ftp:|\/\/|www\.)/i;
// 17 characters, no I/O/Q: looks like a VIN. Never forwarded to a store.
const VIN_LIKE = /(^|[^A-Za-z0-9])[A-HJ-NPR-Za-hj-npr-z0-9]{17}($|[^A-Za-z0-9])/;

function fail(code) {
  return { ok: false, code };
}

// Validates the plain-text fields the app may send. Returns { ok, q } or { ok:false, code }.
function parseGuideQuery(query = {}, now = new Date()) {
  for (const key of Object.keys(query)) {
    if (!ALLOWED_PARAMS.has(key)) return fail('UNKNOWN_PARAMETER');
  }
  const values = {};
  for (const key of ALLOWED_PARAMS) {
    const raw = query[key];
    if (raw === undefined) continue;
    if (typeof raw !== 'string') return fail('INVALID_PARAMETER');
    const value = raw.trim();
    if (!value) continue;
    if (value.length > MAX_FIELD_LENGTH) return fail('PARAMETER_TOO_LONG');
    if (CONTROL_CHARS.test(value)) return fail('INVALID_PARAMETER');
    if (URL_LIKE.test(value)) return fail('URL_NOT_ALLOWED');
    if (VIN_LIKE.test(value)) return fail('IDENTIFIER_NOT_ALLOWED');
    values[key] = value;
  }
  if (!values.part) return fail('PART_REQUIRED');
  if (values.year !== undefined) {
    const year = Number(values.year);
    if (!/^\d{4}$/.test(values.year) || year < 1980 || year > now.getFullYear() + 1) return fail('INVALID_YEAR');
  }
  const q = [values.make, values.model, values.year, values.part].filter(Boolean).join(' ');
  if (q.length > MAX_QUERY_LENGTH) return fail('PARAMETER_TOO_LONG');
  return { ok: true, q };
}

// Reads "key=value&key2=value2" from the store's AFFILIATE_* variable, keeping only
// harmless-looking pairs. Anything else is ignored (never breaks the redirect).
function affiliateParams(store, env = process.env) {
  if (!store.affiliateEnv) return [];
  const raw = String(env[store.affiliateEnv] || '').trim().replace(/^[?&]/, '');
  if (!raw || raw.length > 200) return [];
  const pairs = [];
  for (const [key, value] of new URLSearchParams(raw)) {
    if (/^[A-Za-z0-9_.-]{1,40}$/.test(key) && value.length > 0 && value.length <= 100) pairs.push([key, value]);
  }
  return pairs;
}

function hostsWithSearch(env) {
  return enabledStoreKeys(env)
    .map((key) => STORES[key])
    .filter((store) => store.host && store.searchUrl)
    .map((store) => store.host);
}

// Returns { ok:true, url } or { ok:false, code }. `store` must be an enabled key.
function buildDestination(storeKey, q, env = process.env) {
  if (typeof storeKey !== 'string' || !Object.hasOwn(STORES, storeKey)) return fail('UNKNOWN_STORE');
  if (!enabledStoreKeys(env).includes(storeKey)) return fail('STORE_DISABLED');
  const store = STORES[storeKey];
  const base = store.searchUrl
    ? store.searchUrl(q, { siteHosts: hostsWithSearch(env) })
    : `https://${store.host}/`;
  const url = new URL(base);
  if (url.protocol !== 'https:') return fail('UNKNOWN_STORE');
  for (const [key, value] of affiliateParams(store, env)) {
    if (!url.searchParams.has(key)) url.searchParams.set(key, value);
  }
  return { ok: true, url: url.toString() };
}

function listEnabledStores(env = process.env) {
  return enabledStoreKeys(env).map((key) => ({ key, name: STORES[key].name }));
}

module.exports = { parseGuideQuery, buildDestination, listEnabledStores, affiliateParams, MAX_FIELD_LENGTH };
