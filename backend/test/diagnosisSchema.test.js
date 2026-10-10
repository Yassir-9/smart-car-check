const test = require('node:test');
const assert = require('node:assert/strict');
const { validateDiagnosis, fallbackDiagnosis, DIAGNOSIS_RESPONSE_SCHEMA } = require('../services/diagnosis/diagnosisSchema');

const valid = {
  title: 'احتمال خلل إشعال', summary: 'يلزم فحص منظم', severity: 'medium', confidence: 70,
  can_drive: true, drive_advice: 'قيادة حذرة', likely_causes: [], recommended_checks: [],
  possible_parts: [], next_step: 'فحص البواجي', workshop_questions: [], warnings: [], obd_codes: [],
};

test('accepts the structured diagnosis contract', () => {
  assert.deepEqual(validateDiagnosis(valid), []);
});

test('English fallback is localized while the response schema remains unchanged', () => {
  const schemaSnapshot = JSON.stringify(DIAGNOSIS_RESPONSE_SCHEMA);
  const fallback = fallbackDiagnosis(undefined, 'en');
  assert.equal(fallback.title, 'Analysis incomplete');
  assert.match(fallback.drive_advice, /red warning light/i);
  assert.deepEqual(validateDiagnosis(fallback), []);
  assert.equal(JSON.stringify(DIAGNOSIS_RESPONSE_SCHEMA), schemaSnapshot);
});

test('rejects malformed responses and fallback remains safe', () => {
  assert.ok(validateDiagnosis({ severity: 'certain' }).length > 0);
  assert.ok(validateDiagnosis({ ...valid, likely_causes: [42] }).length > 0);
  assert.ok(validateDiagnosis({ ...valid, obd_codes: ['P0133'] }).length > 0);
  const fallback = fallbackDiagnosis();
  assert.equal(fallback.confidence, 0);
  assert.equal(fallback.can_drive, false);
});
