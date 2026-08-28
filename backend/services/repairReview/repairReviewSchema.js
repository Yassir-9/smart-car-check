const STATUSES = new Set(['logical', 'verify', 'stop']);
const EVIDENCE = new Set(['strong', 'partial', 'insufficient']);

const REPAIR_REVIEW_SCHEMA = {
  type: 'object',
  required: ['status', 'summary', 'aligned_evidence', 'evidence_needed', 'technician_questions', 'recommended_checks', 'parts', 'price', 'safety'],
  properties: {
    status: { type: 'string', enum: [...STATUSES] },
    summary: { type: 'string', maxLength: 500 },
    aligned_evidence: { type: 'array', maxItems: 6, items: { type: 'string', maxLength: 240 } },
    evidence_needed: { type: 'array', maxItems: 6, items: { type: 'string', maxLength: 240 } },
    technician_questions: { type: 'array', minItems: 2, maxItems: 5, items: { type: 'string', maxLength: 220 } },
    recommended_checks: { type: 'array', minItems: 2, maxItems: 6, items: { type: 'string', maxLength: 220 } },
    parts: { type: 'array', maxItems: 12, items: { type: 'object', required: ['name', 'workshop_reason', 'evidence', 'explanation'], properties: {
      name: { type: 'string', maxLength: 100 }, workshop_reason: { type: 'string', maxLength: 220 },
      evidence: { type: 'string', enum: [...EVIDENCE] }, explanation: { type: 'string', maxLength: 300 },
    } } },
    price: { type: 'object', required: ['market_judgment', 'note'], properties: {
      market_judgment: { type: 'string', enum: ['insufficient_market_data'] }, note: { type: 'string', maxLength: 300 },
      quoted_total: { type: 'number', nullable: true }, calculated_total: { type: 'number', nullable: true }, discrepancy: { type: 'number', nullable: true },
    } },
    safety: { type: 'object', required: ['critical', 'advice'], properties: {
      critical: { type: 'boolean' }, advice: { type: 'string', maxLength: 300 },
    } },
    warnings: { type: 'array', maxItems: 5, items: { type: 'string', maxLength: 220 } },
  },
};

function strings(value, max = 8) {
  return Array.isArray(value) ? value.filter((v) => typeof v === 'string' && v.trim()).slice(0, max).map((v) => v.trim()) : [];
}

function validateRepairReview(value) {
  const errors = [];
  if (!value || typeof value !== 'object' || Array.isArray(value)) return ['result must be an object'];
  if (!STATUSES.has(value.status)) errors.push('status is invalid');
  if (typeof value.summary !== 'string' || !value.summary.trim()) errors.push('summary is required');
  for (const key of ['aligned_evidence', 'evidence_needed', 'technician_questions', 'recommended_checks']) {
    if (!Array.isArray(value[key]) || value[key].some((v) => typeof v !== 'string')) errors.push(`${key} must contain strings`);
  }
  if (Array.isArray(value.technician_questions) && (value.technician_questions.length < 2 || value.technician_questions.length > 5)) errors.push('technician_questions must contain 2 to 5 items');
  if (Array.isArray(value.recommended_checks) && (value.recommended_checks.length < 2 || value.recommended_checks.length > 6)) errors.push('recommended_checks must contain 2 to 6 items');
  if (!Array.isArray(value.parts) || value.parts.some((part) => !part || typeof part.name !== 'string' || !EVIDENCE.has(part.evidence))) errors.push('parts is invalid');
  if (!value.price || value.price.market_judgment !== 'insufficient_market_data') errors.push('price judgment is invalid');
  if (!value.safety || typeof value.safety.critical !== 'boolean' || typeof value.safety.advice !== 'string') errors.push('safety is invalid');
  return errors;
}

function normalizeRepairReview(value) {
  return {
    analysis_complete: true,
    status: STATUSES.has(value.status) ? value.status : 'verify',
    summary: String(value.summary),
    aligned_evidence: strings(value.aligned_evidence),
    evidence_needed: strings(value.evidence_needed),
    technician_questions: strings(value.technician_questions, 5).slice(0, 5),
    recommended_checks: strings(value.recommended_checks),
    parts: (Array.isArray(value.parts) ? value.parts : []).slice(0, 12).map((part) => ({
      name: String(part.name || 'قطعة غير محددة'),
      workshop_reason: String(part.workshop_reason || 'لم يذكر السبب'),
      evidence: EVIDENCE.has(part.evidence) ? part.evidence : 'insufficient',
      explanation: String(part.explanation || 'لا تتوفر أدلة كافية.'),
    })),
    price: {
      market_judgment: 'insufficient_market_data',
      note: 'لا تتوفر لدينا بيانات سوق سعودية موثوقة كافية للحكم على السعر حاليًا.',
      quoted_total: Number.isFinite(value.price?.quoted_total) ? value.price.quoted_total : null,
      calculated_total: Number.isFinite(value.price?.calculated_total) ? value.price.calculated_total : null,
      discrepancy: Number.isFinite(value.price?.discrepancy) ? value.price.discrepancy : null,
    },
    safety: { critical: value.safety?.critical === true, advice: String(value.safety?.advice || '') },
    warnings: strings(value.warnings, 5),
  };
}

function fallbackRepairReview() {
  return {
    analysis_complete: false, status: 'verify',
    summary: 'تعذر إنشاء مراجعة موثوقة للعرض. لم نفترض أن التشخيص أو القطع المقترحة صحيحة.',
    aligned_evidence: [], evidence_needed: ['نتيجة فحص موثقة تشرح سبب تغيير كل قطعة'],
    technician_questions: ['ما الاختبار الذي أثبت أن القطعة هي سبب العطل؟'],
    recommended_checks: ['اطلب نتيجة الفحص قبل الموافقة على تغيير القطعة'], parts: [],
    price: { market_judgment: 'insufficient_market_data', note: 'لا تتوفر لدينا بيانات سوق سعودية موثوقة كافية للحكم على السعر حاليًا.', quoted_total: null, calculated_total: null, discrepancy: null },
    safety: { critical: false, advice: 'إذا كانت المشكلة مرتبطة بالفرامل أو الزيت أو الحرارة أو الدخان، لا تقد السيارة قبل فحصها.' },
    warnings: ['لم تكتمل عملية التحليل'],
  };
}

module.exports = { REPAIR_REVIEW_SCHEMA, validateRepairReview, normalizeRepairReview, fallbackRepairReview };
