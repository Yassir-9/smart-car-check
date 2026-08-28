const obdDatabase = require('../../knowledge_base/obd_codes.json');

function normalizeObdCodes(codes) {
  if (!Array.isArray(codes)) return [];
  return [...new Set(codes
    .filter((code) => typeof code === 'string')
    .map((code) => code.trim().toUpperCase())
    .filter((code) => /^[PCBU][0-3][0-9A-F]{3}$/.test(code)))]
    .slice(0, 20);
}

function localObdContext(codes) {
  return codes.map((code) => {
    const local = obdDatabase[code];
    return local
      ? { code, known: true, official_title: local.title_ar, severity: local.severity, likely_causes: local.common_causes }
      : { code, known: false };
  });
}

function enrichObdResults(codes, aiItems, diagnosis) {
  const byCode = new Map((Array.isArray(aiItems) ? aiItems : [])
    .filter((item) => item && typeof item.code === 'string')
    .map((item) => [item.code.trim().toUpperCase(), item]));
  return codes.map((code) => {
    const local = obdDatabase[code];
    const ai = byCode.get(code) || {};
    return {
      code,
      official_title: local?.title_ar || 'غير موجود في قاعدة Smart Car Check المحلية',
      meaning: local?.title_ar || String(ai.meaning || 'تفسير محتمل يحتاج تحققًا فنيًا'),
      severity: local?.severity || String(ai.severity || 'غير محددة'),
      likely_causes: local?.common_causes || [],
      recommended_checks: Array.isArray(ai.recommended_checks) ? ai.recommended_checks.slice(0, 8) : [],
      possible_parts: Array.isArray(ai.possible_parts) ? ai.possible_parts.slice(0, 8) : [],
      can_drive: diagnosis.can_drive,
      drive_advice: diagnosis.drive_advice,
      urgent: ai.urgent === true || diagnosis.severity === 'critical',
      next_step: String(ai.next_step || diagnosis.next_step),
      locally_verified: !!local,
      interpretation_notice: local
        ? null
        : 'هذا تفسير محتمل من الذكاء الاصطناعي وليس تعريفًا مؤكدًا في قاعدة Smart Car Check المحلية.',
    };
  });
}

module.exports = { normalizeObdCodes, localObdContext, enrichObdResults };
