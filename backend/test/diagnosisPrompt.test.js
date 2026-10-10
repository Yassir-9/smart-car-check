const test = require('node:test');
const assert = require('node:assert/strict');

const { buildDiagnosisPrompts } = require('../services/diagnosis/diagnosisPrompt');

const car = { brand: 'Nissan', model: 'Maxima', year: 2016 };
const obd = [{ code: 'P0133', known: true, official_title: 'بطء استجابة حساس الأكسجين' }];

for (const combination of [
  { name: 'symptoms only', description: 'تنتفض عند التسارع', obdContext: [], hasImage: false },
  { name: 'image only', description: '', obdContext: [], hasImage: true },
  { name: 'OBD only', description: '', obdContext: obd, hasImage: false },
  { name: 'symptoms and image', description: 'لمبة المكينة', obdContext: [], hasImage: true },
  { name: 'symptoms and OBD', description: 'صرف وقود مرتفع', obdContext: obd, hasImage: false },
  { name: 'image and OBD', description: '', obdContext: obd, hasImage: true },
  { name: 'symptoms, image, and OBD', description: 'رجة عند التسارع', obdContext: obd, hasImage: true },
]) {
  test(`builds one contextual prompt for ${combination.name}`, () => {
    const result = buildDiagnosisPrompts({
      car,
      ...combination,
      schemaDescription: '{schema}',
    });
    const payload = JSON.parse(result.prompt);
    assert.deepEqual(payload.vehicle, { make: 'Nissan', model: 'Maxima', year: 2016 });
    assert.equal(payload.symptoms, combination.description || null);
    assert.deepEqual(payload.scanned_obd_codes, combination.obdContext);
    assert.equal(payload.image_attached, combination.hasImage);
    assert.match(payload.instruction, /جميع المصادر المتاحة معًا/);
  });
}

test('prompt distinguishes evidence, probability, recommendations, and critical safety', () => {
  const { system } = buildDiagnosisPrompts({
    car,
    description: 'لمبة زيت حمراء',
    obdContext: [],
    hasImage: false,
    schemaDescription: '{schema}',
  });
  assert.match(system, /البيانات المؤكدة/);
  assert.match(system, /الأسباب المحتملة/);
  assert.match(system, /الفحوصات الموصى بها/);
  assert.match(system, /لمبة زيت حمراء/);
  assert.match(system, /فقدان فرامل/);
  assert.match(system, /can_drive=false/);
  assert.match(system, /الصورة غير واضحة أو غير مرتبطة/);
});

test('English locale requests English output without changing safety rules or schema keys', () => {
  const { system, prompt } = buildDiagnosisPrompts({
    car, description: 'red oil warning', obdContext: obd, hasImage: false,
    schemaDescription: '{schema}', locale: 'en',
  });
  const payload = JSON.parse(prompt);
  assert.equal(payload.response_locale, 'en');
  assert.match(system, /all user-facing explanations and recommendations in English/i);
  assert.match(system, /red oil warning/i);
  assert.match(system, /can_drive=false/);
  assert.match(system, /DTC codes, numbers, units/i);
  assert.match(system, /Schema: \{schema\}/);
});

test('missing and unsupported locale remain backward-compatible Arabic', () => {
  for (const locale of [undefined, 'fr']) {
    const built = buildDiagnosisPrompts({ car, description: '', obdContext: [], hasImage: true, schemaDescription: '{schema}', locale });
    assert.equal(JSON.parse(built.prompt).response_locale, 'ar');
    assert.match(built.system, /اكتب جميع الشروحات والتوصيات.*بالعربية/);
  }
});
