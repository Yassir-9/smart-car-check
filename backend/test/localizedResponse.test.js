const test = require('node:test');
const assert = require('node:assert/strict');
const {
  requestLocale,
  localizedError,
  localizedPaymentSuccess,
} = require('../utils/localizedResponse');

function request({ body = {}, header, query = {} } = {}) {
  return {
    body,
    query,
    get(name) {
      return name === 'X-App-Locale' ? header : undefined;
    },
  };
}

test('backend user messages support Arabic and English with stable codes', () => {
  const ar = localizedError(request(), 'EMPTY_CART');
  const en = localizedError(request({ header: 'en' }), 'EMPTY_CART');
  assert.equal(ar.code, 'EMPTY_CART');
  assert.equal(en.code, 'EMPTY_CART');
  assert.match(ar.error, /[\u0600-\u06ff]/);
  assert.doesNotMatch(en.error, /[\u0600-\u06ff]/);
});

test('locale accepts body, header, or query and safely defaults to Arabic', () => {
  assert.equal(requestLocale(request({ body: { locale: 'en' } })), 'en');
  assert.equal(requestLocale(request({ header: 'en-US' })), 'en');
  assert.equal(requestLocale(request({ query: { locale: 'en' } })), 'en');
  assert.equal(requestLocale(request({ body: { locale: 'fr' } })), 'ar');
  assert.equal(requestLocale(request()), 'ar');
});

test('unknown error codes fail closed without exposing internals', () => {
  const result = localizedError(request({ header: 'en' }), 'UNKNOWN_CODE');
  assert.equal(result.code, 'UNKNOWN_CODE');
  assert.equal(result.error, 'An error occurred. Try again.');
});

test('payment success pages follow locale and direction', () => {
  const english = localizedPaymentSuccess(request({ query: { locale: 'en' } }), 'order');
  assert.equal(english.locale, 'en');
  assert.equal(english.direction, 'ltr');
  assert.match(english.body, /follow your order/);

  const arabic = localizedPaymentSuccess(request(), 'subscription');
  assert.equal(arabic.locale, 'ar');
  assert.equal(arabic.direction, 'rtl');
  assert.match(arabic.body, /الاستمتاع بالاشتراك/);
});
