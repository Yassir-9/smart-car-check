const test = require('node:test');
const assert = require('node:assert/strict');

const {
  isDevelopmentUsageLimitBypassEnabled,
  isQaUsageLimitBypassEnabled,
} = require('../services/diagnosis/usageLimit');

test('production QA bypass requires explicit production allow flag and UID', () => {
  const base = { NODE_ENV: 'production', QA_USAGE_LIMIT_ENABLED: 'true', QA_USAGE_LIMIT_UIDS: 'qa-uid' };
  assert.equal(isQaUsageLimitBypassEnabled('qa-uid', base), false);
  assert.equal(isQaUsageLimitBypassEnabled('qa-uid', { ...base, QA_USAGE_LIMIT_ALLOW_PRODUCTION: 'true' }), true);
  assert.equal(isQaUsageLimitBypassEnabled('unknown', { ...base, QA_USAGE_LIMIT_ALLOW_PRODUCTION: 'true' }), false);
});

test('QA bypass requires enabled flag, exact UID, and non-expired optional expiry', () => {
  const env = { NODE_ENV: 'qa', QA_USAGE_LIMIT_ENABLED: 'true', QA_USAGE_LIMIT_UIDS: 'qa-uid,other-uid' };
  assert.equal(isQaUsageLimitBypassEnabled('qa-uid', env), true);
  assert.equal(isQaUsageLimitBypassEnabled('unknown', env), false);
  assert.equal(isQaUsageLimitBypassEnabled('qa-uid', { ...env, QA_USAGE_LIMIT_ENABLED: 'false' }), false);
  assert.equal(isQaUsageLimitBypassEnabled('qa-uid', { ...env, QA_USAGE_LIMIT_EXPIRES_AT: '2000-01-01T00:00:00Z' }), false);
  assert.equal(isQaUsageLimitBypassEnabled('qa-uid', { ...env, QA_USAGE_LIMIT_EXPIRES_AT: 'not-a-date' }), false);
});

test('development usage limit bypass works when explicitly enabled', () => {
  assert.equal(
    isDevelopmentUsageLimitBypassEnabled({
      NODE_ENV: 'development',
      DEV_BYPASS_USAGE_LIMIT: 'true',
    }),
    true,
  );
});

test('development usage limit bypass is always disabled in production', () => {
  assert.equal(
    isDevelopmentUsageLimitBypassEnabled({
      NODE_ENV: 'production',
      DEV_BYPASS_USAGE_LIMIT: 'true',
    }),
    false,
  );
  assert.equal(
    isDevelopmentUsageLimitBypassEnabled({
      NODE_ENV: ' Production ',
      DEV_BYPASS_USAGE_LIMIT: 'TRUE',
    }),
    false,
  );
});

test('original usage limit behavior remains when bypass is false', () => {
  assert.equal(
    isDevelopmentUsageLimitBypassEnabled({
      NODE_ENV: 'development',
      DEV_BYPASS_USAGE_LIMIT: 'false',
    }),
    false,
  );
});
