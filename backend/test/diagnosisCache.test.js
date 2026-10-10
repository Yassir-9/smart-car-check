const test = require('node:test');
const assert = require('node:assert/strict');
const { createCacheKey, imageFingerprint } = require('../services/diagnosis/diagnosisCache');

const base = { car: { brand: 'Nissan', model: 'Maxima', year: 2016 }, description: 'رجة عند الوقوف', obdCodes: ['P0300'] };

test('cache key is stable for normalized input', () => {
  const first = createCacheKey({ ...base, uid: 'user-a' });
  const second = createCacheKey({ ...base, uid: 'user-a', description: '  رجة   عند الوقوف ' });
  assert.equal(first, second);
});

test('cache is isolated by user and image fingerprint', () => {
  assert.notEqual(createCacheKey({ ...base, uid: 'user-a' }), createCacheKey({ ...base, uid: 'user-b' }));
  assert.notEqual(imageFingerprint({ data: 'image-one' }), imageFingerprint({ data: 'image-two' }));
});

test('cache is isolated by response locale and defaults to Arabic', () => {
  assert.equal(
    createCacheKey({ ...base, uid: 'user-a' }),
    createCacheKey({ ...base, uid: 'user-a', locale: 'ar' }),
  );
  assert.notEqual(
    createCacheKey({ ...base, uid: 'user-a', locale: 'ar' }),
    createCacheKey({ ...base, uid: 'user-a', locale: 'en' }),
  );
});
