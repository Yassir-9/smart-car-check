const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeObdCodes, localObdContext, enrichObdResults } = require('../services/diagnosis/obdEnrichment');

test('normalizes real OBD codes and rejects invalid values', () => {
  assert.deepEqual(normalizeObdCodes(['p0300', 'P0300', 'fake', null]), ['P0300']);
});

test('local definition cannot be replaced by AI', () => {
  const context = localObdContext(['P0300']);
  const result = enrichObdResults(['P0300'], [{ code: 'P0300', meaning: 'تعريف مزيف' }], {
    can_drive: true, drive_advice: 'بحذر', severity: 'medium', next_step: 'افحص',
  });
  assert.equal(result[0].official_title, context[0].official_title);
  assert.equal(result[0].meaning, context[0].official_title);
  assert.equal(result[0].locally_verified, true);
});

test('unknown codes are explicitly marked as unverified', () => {
  const result = enrichObdResults(['P3999'], [{ code: 'P3999', meaning: 'تفسير محتمل' }], {
    can_drive: false, drive_advice: 'توقف', severity: 'high', next_step: 'فحص',
  });
  assert.equal(result[0].locally_verified, false);
  assert.match(result[0].interpretation_notice, /ليس تعريفًا مؤكدًا/);
});
