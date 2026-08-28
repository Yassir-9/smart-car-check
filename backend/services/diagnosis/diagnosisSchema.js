const SEVERITIES = new Set(['low', 'medium', 'high', 'critical']);
const DIAGNOSIS_RESPONSE_SCHEMA = {
  type: 'object',
  required: ['title', 'summary', 'severity', 'confidence', 'can_drive', 'drive_advice', 'likely_causes', 'recommended_checks', 'possible_parts', 'next_step', 'workshop_questions', 'warnings', 'obd_codes'],
  properties: {
    title: { type: 'string' }, summary: { type: 'string' },
    severity: { type: 'string', enum: ['low', 'medium', 'high', 'critical'] },
    confidence: { type: 'number' }, can_drive: { type: 'boolean' }, drive_advice: { type: 'string' },
    likely_causes: { type: 'array', items: { type: 'string' } },
    recommended_checks: { type: 'array', items: { type: 'string' } },
    possible_parts: { type: 'array', items: { type: 'string' } },
    next_step: { type: 'string' }, workshop_questions: { type: 'array', items: { type: 'string' } },
    warnings: { type: 'array', items: { type: 'string' } },
    obd_codes: { type: 'array', items: { type: 'object', required: ['code', 'meaning', 'severity', 'recommended_checks'], properties: {
      code: { type: 'string' }, meaning: { type: 'string' }, severity: { type: 'string' },
      recommended_checks: { type: 'array', items: { type: 'string' } },
      possible_parts: { type: 'array', items: { type: 'string' } }, urgent: { type: 'boolean' }, next_step: { type: 'string' },
    } } },
  },
};

function stringList(value, max = 8) {
  return Array.isArray(value)
    ? value.filter((item) => typeof item === 'string' && item.trim()).slice(0, max).map((item) => item.trim())
    : [];
}

function validateDiagnosis(value) {
  const errors = [];
  if (!value || typeof value !== 'object' || Array.isArray(value)) return ['result must be an object'];
  for (const field of ['title', 'summary', 'drive_advice', 'next_step']) {
    if (typeof value[field] !== 'string' || !value[field].trim()) errors.push(`${field} is required`);
  }
  if (!SEVERITIES.has(value.severity)) errors.push('severity is invalid');
  if (typeof value.confidence !== 'number' || value.confidence < 0 || value.confidence > 100) {
    errors.push('confidence must be between 0 and 100');
  }
  if (typeof value.can_drive !== 'boolean') errors.push('can_drive must be boolean');
  for (const field of ['likely_causes', 'recommended_checks', 'possible_parts', 'workshop_questions', 'warnings']) {
    if (!Array.isArray(value[field])) errors.push(`${field} must be an array`);
    else if (value[field].some((item) => typeof item !== 'string')) errors.push(`${field} must contain strings`);
  }
  if (!Array.isArray(value.obd_codes)) {
    errors.push('obd_codes must be an array');
  } else {
    value.obd_codes.forEach((item, index) => {
      if (!item || typeof item !== 'object' || Array.isArray(item)) {
        errors.push(`obd_codes[${index}] must be an object`);
        return;
      }
      for (const field of ['code', 'meaning', 'severity']) {
        if (typeof item[field] !== 'string' || !item[field].trim()) {
          errors.push(`obd_codes[${index}].${field} is required`);
        }
      }
      if (!Array.isArray(item.recommended_checks) ||
          item.recommended_checks.some((check) => typeof check !== 'string')) {
        errors.push(`obd_codes[${index}].recommended_checks must contain strings`);
      }
    });
  }
  return errors;
}

function normalizeDiagnosis(value) {
  const severity = SEVERITIES.has(value?.severity) ? value.severity : 'medium';
  const confidence = Number.isFinite(value?.confidence)
    ? Math.max(0, Math.min(100, Math.round(value.confidence)))
    : 0;
  return {
    title: String(value?.title || 'تعذر تحديد المشكلة بدقة'),
    summary: String(value?.summary || 'البيانات الحالية غير كافية لتشخيص موثوق.'),
    severity,
    confidence,
    can_drive: value?.can_drive === true,
    drive_advice: String(value?.drive_advice || 'تجنب القيادة إذا ظهرت أعراض تؤثر على السلامة.'),
    likely_causes: stringList(value?.likely_causes),
    recommended_checks: stringList(value?.recommended_checks),
    possible_parts: stringList(value?.possible_parts),
    next_step: String(value?.next_step || 'اطلب فحصًا مباشرًا من فني مؤهل.'),
    workshop_questions: stringList(value?.workshop_questions),
    warnings: stringList(value?.warnings),
    obd_codes: Array.isArray(value?.obd_codes) ? value.obd_codes.slice(0, 20) : [],
  };
}

function fallbackDiagnosis(reason = 'تعذر التحقق من استجابة نظام التحليل') {
  return normalizeDiagnosis({
    title: 'التحليل غير مكتمل',
    summary: 'لم نتمكن من إنشاء نتيجة موثوقة من البيانات الحالية. لم يتم افتراض عطل أو قطعة تالفة.',
    severity: 'medium',
    confidence: 0,
    can_drive: false,
    drive_advice: 'إذا كانت هناك لمبة تحذير حمراء أو تغير في الفرامل أو التوجيه أو حرارة المحرك، أوقف السيارة واطلب فحصًا مباشرًا.',
    likely_causes: [],
    recommended_checks: ['إعادة الفحص ببيانات أوضح', 'قراءة أكواد OBD لدى فني مؤهل'],
    possible_parts: [],
    next_step: 'أعد المحاولة أو اعرض السيارة على فني مؤهل.',
    workshop_questions: ['ما الاختبار الذي يؤكد سبب العطل قبل تغيير أي قطعة؟'],
    warnings: [reason],
    obd_codes: [],
  });
}

function addLegacyAliases(result) {
  const severityAr = { low: 'منخفضة', medium: 'متوسطة', high: 'عالية', critical: 'عالية' };
  return {
    ...result,
    possible_issue: result.title,
    explanation: result.summary,
    confidence_score: result.confidence,
    confidence_reason: result.confidence === 0 ? 'تعذر التحقق من مخرجات التحليل' : 'النسبة مبنية على البيانات المتاحة وجودة تطابقها',
    recommendations: result.recommended_checks,
    severity_code: result.severity,
    severity_ar: severityAr[result.severity] || 'متوسطة',
    can_drive_text: result.drive_advice,
    estimated_cost: null,
  };
}

module.exports = { validateDiagnosis, normalizeDiagnosis, fallbackDiagnosis, addLegacyAliases, SEVERITIES, DIAGNOSIS_RESPONSE_SCHEMA };
