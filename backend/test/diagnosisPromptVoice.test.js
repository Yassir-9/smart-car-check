const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildDiagnosisPrompts, SAFETY_INSTRUCTIONS, SAFETY_INSTRUCTIONS_EN, SUMMARY_VOICE, SUMMARY_VOICE_EN, PARTS_TERMS, PARTS_TERMS_EN,
} = require('../services/diagnosis/diagnosisPrompt');

const base = { car: { brand: 'Nissan', model: 'Maxima', year: 2016 }, description: 'اهتزاز', obdContext: [], hasImage: false, schemaDescription: '{schema}' };
const ar = () => buildDiagnosisPrompts({ ...base, locale: 'ar' });
const en = () => buildDiagnosisPrompts({ ...base, locale: 'en' });

// The system prompts exactly as they were before this change (frozen copies).
const OLD_AR = `أنت محلل أعطال سيارات إرشادي. أرجع JSON فقط حسب المخطط. ${SAFETY_INSTRUCTIONS} قاعدة OBD المحلية هي المرجع الملزم لتعريف الأكواد المعروفة ولا يجوز تغييرها. الكود غير المعروف محليًا تفسيره احتمال غير مؤكد. اكتب جميع الشروحات والتوصيات الظاهرة للمستخدم بالعربية مع الحفاظ على مفاتيح JSON ورموز DTC والأرقام والوحدات والمصطلحات الفنية. المخطط: {schema}`;
const OLD_EN = `You are an automotive diagnostic guidance assistant. Return JSON only according to the schema. ${SAFETY_INSTRUCTIONS_EN} The local OBD database is authoritative for known code definitions and must not be contradicted. An unknown local code is an unconfirmed possible interpretation. Write all user-facing explanations and recommendations in English while preserving JSON keys, DTC codes, numbers, units, and technical identifiers. Schema: {schema}`;

test('the Arabic prompt tells the model to address the reader, not "the user"', () => {
  const { system } = ar();
  assert.ok(system.includes(SUMMARY_VOICE));
  assert.match(SUMMARY_VOICE, /summary/);
  assert.match(SUMMARY_VOICE, /ذكرتَ أن/);
  assert.match(SUMMARY_VOICE, /الشكوى المسجّلة/);
  // the third person only appears inside the prohibition itself
  const withoutProhibition = system.replace('«يشتكي المستخدم»', '');
  assert.doesNotMatch(withoutProhibition, /يشتكي المستخدم/);
});

test('the English prompt has the same instruction', () => {
  const { system } = en();
  assert.ok(system.includes(SUMMARY_VOICE_EN));
  assert.match(SUMMARY_VOICE_EN, /addressed directly to the reader/);
  assert.match(SUMMARY_VOICE_EN, /You mentioned that/);
  assert.match(system.replace('"The user complains"', ''), /^(?![\s\S]*The user complains)/);
});

test('nothing else in the system prompts changed: removing the new sentence gives the old prompt exactly', () => {
  assert.equal(ar().system.replace(` ${PARTS_TERMS}`, '').replace(` ${SUMMARY_VOICE}`, ''), OLD_AR);
  assert.equal(en().system.replace(` ${PARTS_TERMS_EN}`, '').replace(` ${SUMMARY_VOICE_EN}`, ''), OLD_EN);
});

test('the user prompt payload is untouched', () => {
  const payload = JSON.parse(ar().prompt);
  assert.deepEqual(Object.keys(payload), ['vehicle', 'symptoms', 'scanned_obd_codes', 'image_attached', 'response_locale', 'instruction']);
  assert.match(payload.instruction, /جميع المصادر المتاحة معًا/);
});

test('the prompts ask for the English technical term of each possible part', () => {
  assert.ok(ar().system.includes(PARTS_TERMS));
  assert.match(PARTS_TERMS, /possible_parts/);
  assert.match(PARTS_TERMS, /بين قوسين/);
  assert.match(PARTS_TERMS, /Spark Plugs/);
  assert.ok(en().system.includes(PARTS_TERMS_EN));
  assert.match(PARTS_TERMS_EN, /possible_parts/);
});
