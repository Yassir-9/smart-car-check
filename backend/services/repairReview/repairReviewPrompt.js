const { normalizeLocale } = require('../diagnosis/diagnosisPrompt');

function buildRepairReviewPrompt(input, locale) {
  const language = normalizeLocale(locale);
  const system = language === 'en'
    ? 'You help a vehicle owner decide before approving a repair. Do not accuse the workshop or confirm that a part has failed. Separate confirmed data, possible causes, and items needing evidence. Use only: insufficient evidence, needs verification, or request test evidence. Do not judge a price as high or low because there is no trusted Saudi market price database; market_judgment must always be insufficient_market_data. For brake loss, severe overheating, dangerous oil pressure, smoke, or fire, set safety.critical=true and prioritize safety over price. If an image is unrelated to a workshop quote or vehicle, state that and draw no conclusion from it. Return JSON only according to the supplied schema. Write all user-facing text in English while preserving JSON keys, numbers, units, part numbers, and technical identifiers.'
    : 'أنت مساعد قرار لصاحب سيارة قبل الموافقة على إصلاح. لا تتهم الورشة ولا تؤكد تلف قطعة. افصل بين البيانات المؤكدة والأسباب المحتملة وما يحتاج إثباتًا. استخدم فقط: لا توجد أدلة كافية، يحتاج تحقق، اطلب إثبات الفحص. لا تحكم أن السعر مرتفع أو منخفض لعدم وجود قاعدة أسعار سعودية موثوقة؛ اجعل market_judgment دائمًا insufficient_market_data. إذا وجدت فقدان فرامل أو حرارة شديدة أو ضغط زيت خطير أو دخان أو حريق، اجعل safety.critical=true وقدم السلامة على السعر. إذا كانت الصورة غير مرتبطة بعرض ورشة أو سيارة فاذكر ذلك ولا تستنتج منها. أرجع JSON فقط حسب المخطط المرسل. اكتب جميع النصوص الظاهرة للمستخدم بالعربية مع الحفاظ على مفاتيح JSON والأرقام والوحدات وأرقام القطع والمصطلحات الفنية.';
  return { system, prompt: JSON.stringify({
    ...input,
    response_locale: language,
    instruction: language === 'en'
      ? 'Combine all sources into one concise decision review. Create 2–5 questions and 2–6 checks. Include only the parts actually supplied in parts; do not add new parts.'
      : 'ادمج جميع المصادر في مراجعة قرار واحدة مختصرة. أنشئ 2–5 أسئلة و2–6 فحوصات. أدرج في parts القطع الفعلية المدخلة فقط ولا تضف قطعًا جديدة.',
  }) };
}

function buildRepairReviewCorrectionPrompt(input, reason, locale) {
  const language = normalizeLocale(locale);
  return JSON.stringify({
    ...input,
    response_locale: language,
    correction: language === 'en'
      ? `Create new valid and complete JSON according to the schema. Keep text concise and add no information. Retry reason: ${reason}`
      : `أنشئ JSON جديدًا صالحًا ومكتملًا حسب المخطط. اختصر النصوص ولا تضف معلومات. سبب إعادة المحاولة: ${reason}`,
  });
}

module.exports = { buildRepairReviewPrompt, buildRepairReviewCorrectionPrompt };
