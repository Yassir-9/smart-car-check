const test = require('node:test');
const assert = require('node:assert/strict');

const { normalizeDiagnosisImage } = require('../services/diagnosis/diagnosisImage');

test('accepts a supported base64 image and preserves its MIME type', () => {
  const data = Buffer.from('test-image').toString('base64');
  assert.deepEqual(normalizeDiagnosisImage({ data, media_type: 'image/png' }), {
    image: { data, media_type: 'image/png' },
  });
  assert.deepEqual(normalizeDiagnosisImage({ data, media_type: 'image/heic' }), {
    image: { data, media_type: 'image/heic' },
  });
});

test('rejects malformed, unsupported, and empty images', () => {
  assert.ok(normalizeDiagnosisImage({ data: 'not base64!', media_type: 'image/jpeg' }).error);
  assert.ok(normalizeDiagnosisImage({ data: 'YWJj', media_type: 'text/plain' }).error);
  assert.ok(normalizeDiagnosisImage({ data: '', media_type: 'image/jpeg' }).error);
});
