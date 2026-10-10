const test = require('node:test');
const assert = require('node:assert/strict');
const { buildRepairReviewPrompt } = require('../services/repairReview/repairReviewPrompt');
const { validateRepairReview, normalizeRepairReview, fallbackRepairReview, REPAIR_REVIEW_SCHEMA } = require('../services/repairReview/repairReviewSchema');

const valid = {
  status: 'verify', summary: 'يحتاج العرض إلى إثبات فني.',
  aligned_evidence: [], evidence_needed: ['نتيجة قياس'],
  technician_questions: ['هل يمكن أن تريني نتيجة القياس؟', 'ما البديل قبل تغيير القطعة؟'], recommended_checks: ['فحص مباشر', 'قياس موثق'],
  parts: [{ name: 'المقص', workshop_reason: 'وجود صوت', evidence: 'insufficient', explanation: 'الصوت وحده لا يثبت تلف القطعة.' }],
  price: { market_judgment: 'insufficient_market_data', note: 'لا تتوفر بيانات سوق.', quoted_total: 1000, calculated_total: null, discrepancy: null },
  safety: { critical: false, advice: 'اتبع تعليمات السلامة.' }, warnings: [],
};

for (const [name, input] of Object.entries({
  'workshop text only': { workshop_statement: 'تغيير المساعد', proposed_parts: [], quote_image_attached: false },
  'parts and price': { workshop_statement: null, proposed_parts: ['مساعد'], quoted_price_sar: 900, quote_image_attached: false },
  'quote image only': { workshop_statement: null, proposed_parts: [], quote_image_attached: true },
  'diagnosis and workshop': { workshop_statement: 'تغيير حساس', previous_diagnosis: { title: 'خلل محتمل' }, quote_image_attached: false },
  'OBD and workshop': { workshop_statement: 'تغيير حساس', scanned_obd_codes: [{ code: 'P0133' }], quote_image_attached: false },
  'all sources': { workshop_statement: 'إصلاح', proposed_parts: ['حساس'], quoted_price_sar: 800, previous_diagnosis: { title: 'خلل' }, scanned_obd_codes: [{ code: 'P0133' }], quote_image_attached: true },
  'incomplete data': { workshop_statement: null, proposed_parts: [], quote_image_attached: false },
})) {
  test(`repair review prompt includes ${name}`, () => {
    const built = buildRepairReviewPrompt(input);
    const { instruction, response_locale: responseLocale, ...promptInput } = JSON.parse(built.prompt);
    assert.deepEqual(promptInput, input);
    assert.equal(responseLocale, 'ar');
    assert.equal(typeof instruction, 'string');
    assert.match(built.system, /لا تتهم الورشة/);
    assert.match(built.system, /insufficient_market_data/);
  });
}

test('validates evidence and never invents a market price judgment', () => {
  assert.deepEqual(validateRepairReview(valid), []);
  const normalized = normalizeRepairReview(valid);
  assert.equal(normalized.parts[0].evidence, 'insufficient');
  assert.equal(normalized.price.market_judgment, 'insufficient_market_data');
  assert.match(normalized.price.note, /لا تتوفر لدينا بيانات سوق سعودية موثوقة/);
});

test('malformed response becomes an explicit incomplete fallback', () => {
  assert.ok(validateRepairReview({ status: 'logical' }).length > 0);
  const fallback = fallbackRepairReview();
  assert.equal(fallback.analysis_complete, false);
  assert.equal(fallback.parts.length, 0);
});

test('safety-critical instruction takes priority over price analysis', () => {
  const built = buildRepairReviewPrompt({ workshop_statement: 'فقدان فرامل ودخان', quoted_price_sar: 1000 });
  assert.match(built.system, /safety\.critical=true/);
  assert.match(built.system, /فقدان فرامل/);
  assert.match(built.system, /قدم السلامة على السعر/);
});

test('English repair review keeps safety and price restrictions unchanged', () => {
  const built = buildRepairReviewPrompt({ workshop_statement: 'brake loss and smoke', quoted_price_sar: 1000 }, 'en');
  const payload = JSON.parse(built.prompt);
  assert.equal(payload.response_locale, 'en');
  assert.match(built.system, /Do not accuse the workshop/);
  assert.match(built.system, /safety\.critical=true/);
  assert.match(built.system, /insufficient_market_data/);
  assert.match(built.system, /safety over price/);
});

test('repair review defaults to Arabic and localizes safe English fallback without schema drift', () => {
  assert.equal(JSON.parse(buildRepairReviewPrompt({}).prompt).response_locale, 'ar');
  const schemaSnapshot = JSON.stringify(REPAIR_REVIEW_SCHEMA);
  const fallback = fallbackRepairReview('en');
  assert.equal(fallback.analysis_complete, false);
  assert.match(fallback.summary, /reliable review/i);
  assert.equal(JSON.stringify(REPAIR_REVIEW_SCHEMA), schemaSnapshot);
});

test('valid structured JSON succeeds without retry', async () => {
  const { generateRepairReview, MAX_OUTPUT_TOKENS } = require('../services/repairReview/repairReviewService');
  const calls = [];
  const result = await generateRepairReview({ provider: { generateJson: async (options) => { calls.push(options); return JSON.stringify(valid); } }, input: {}, image: { data: 'image' } });
  assert.equal(result.analysis_complete, true);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].maxOutputTokens, MAX_OUTPUT_TOKENS);
  assert.ok(calls[0].responseSchema);
});

test('English result uses one AI call and preserves the JSON contract', async () => {
  const { generateRepairReview } = require('../services/repairReview/repairReviewService');
  const english = {
    ...valid,
    summary: 'The quote needs test evidence.',
    evidence_needed: ['A documented measurement'],
    technician_questions: ['Which test confirmed this?', 'What alternative check was done?'],
    recommended_checks: ['Direct inspection', 'Documented measurement'],
    safety: { critical: false, advice: 'Follow safety guidance.' },
  };
  const calls = [];
  const result = await generateRepairReview({
    provider: { generateJson: async (options) => { calls.push(options); return JSON.stringify(english); } },
    input: {}, image: null, locale: 'en',
  });
  assert.equal(calls.length, 1);
  assert.equal(JSON.parse(calls[0].prompt).response_locale, 'en');
  assert.deepEqual(validateRepairReview(result), []);
});

for (const [name, broken] of [['truncated JSON', '{"status":"verify"'], ['unterminated string', '{"status":"verify","summary":"broken']]) {
  test(`${name} triggers one retry without resending the image`, async () => {
    const { generateRepairReview } = require('../services/repairReview/repairReviewService');
    const calls = [];
    const provider = { generateJson: async (options) => { calls.push(options); return calls.length === 1 ? broken : JSON.stringify(valid); } };
    const result = await generateRepairReview({ provider, input: { proposed_parts: ['مقص'] }, image: { data: 'base64' } });
    assert.equal(result.analysis_complete, true);
    assert.equal(calls.length, 2);
    assert.deepEqual(calls[0].image, { data: 'base64' });
    assert.equal(calls[1].image, null);
  });
}

test('retry schema failure returns the safe fallback', async () => {
  const { generateRepairReview } = require('../services/repairReview/repairReviewService');
  let calls = 0;
  const result = await generateRepairReview({ provider: { generateJson: async () => { calls++; return JSON.stringify({ status: 'verify' }); } }, input: {}, image: null });
  assert.equal(calls, 2);
  assert.equal(result.analysis_complete, false);
  assert.equal(result.parts.length, 0);
});
