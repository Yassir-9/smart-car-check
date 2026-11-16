const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { getFreeMonthlyLimit, nextMonthStartIso, DEFAULT_FREE_MONTHLY_LIMIT } = require('../config/limits');

test('free monthly limit defaults to 7 and is overridable by env', () => {
  assert.equal(DEFAULT_FREE_MONTHLY_LIMIT, 7);
  assert.equal(getFreeMonthlyLimit({}), 7);
  assert.equal(getFreeMonthlyLimit({ FREE_MONTHLY_LIMIT: '10' }), 10);
  for (const bad of ['0', '-3', 'abc', '', '2.5x']) {
    assert.equal(getFreeMonthlyLimit({ FREE_MONTHLY_LIMIT: bad }), 7, bad);
  }
});

test('limit resets at the start of next month', () => {
  const dec = nextMonthStartIso(new Date(2026, 11, 15));
  assert.equal(new Date(dec).getFullYear(), 2027);
  assert.equal(new Date(dec).getMonth(), 0);
  assert.equal(new Date(dec).getDate(), 1);
});

test('no hard-coded free limit remains in routes; one source is used', () => {
  for (const file of ['diagnosis.js', 'subscription.js']) {
    const src = fs.readFileSync(path.join(__dirname, '..', 'routes', file), 'utf8');
    assert.doesNotMatch(src, /FREE_MONTHLY_LIMIT\s*=\s*\d/);
    assert.doesNotMatch(src, /freeUsageLimit:\s*\d/);
    assert.match(src, /getFreeMonthlyLimit\(\)/);
  }
});

test('limit-reached response mentions neither payment nor subscription', () => {
  const { limitReachedBody } = require('../services/usage/limitResponse');
  for (const kind of ['diagnosis', 'quote_review']) {
    for (const locale of ['en', 'ar']) {
      const body = limitReachedBody(locale, 7, kind);
      assert.equal(body.code, 'FREE_DIAGNOSIS_LIMIT_REACHED');
      assert.equal(body.subscriptionRequired, false);
      assert.equal(body.freeUsageLimit, 7);
      assert.doesNotMatch(body.error, /subscri|pay|اشتراك|دفع/i);
    }
  }
  const src = fs.readFileSync(path.join(__dirname, '..', 'routes', 'diagnosis.js'), 'utf8');
  assert.match(src, /status\(402\)\.json\(limitReachedBody\(locale, getFreeMonthlyLimit\(\), 'diagnosis'\)\)/);
});
