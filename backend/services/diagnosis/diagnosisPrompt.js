const SAFETY_INSTRUCTIONS = [
  'افصل بوضوح بين البيانات المؤكدة التي قدمها المستخدم أو قاعدة OBD المحلية، والأسباب المحتملة، والفحوصات الموصى بها.',
  'لا تصف أي قطعة بأنها تالفة أو تؤكد تشخيصًا دون فحص مباشر يثبت ذلك.',
  'استخدم لغة احتمالية مثل: قد يكون، يرجح، يحتاج تحققًا.',
  'إذا ذُكرت لمبة زيت حمراء أو حرارة مرتفعة أو فقدان فرامل أو دخان أو حريق، اجعل can_drive=false وتوصية التوقف الآمن وطلب المساعدة واضحة.',
  'إذا كانت الصورة غير واضحة أو غير مرتبطة بالسيارة، صرّح بذلك في warnings ولا تستنتج عطلًا منها.',
  'إذا كانت الصورة هي المصدر الوحيد وكانت غير صالحة للتحليل، أرجع confidence=0 ولا تفترض عطلًا أو قطعة.',
].join(' ');

const SAFETY_INSTRUCTIONS_EN = [
  'Clearly separate confirmed data provided by the user or the local OBD database from possible causes and recommended checks.',
  'Never describe a part as failed or confirm a diagnosis without a direct test that proves it.',
  'Use probabilistic language such as: may be, is likely, and needs verification.',
  'If a red oil warning, high temperature, brake loss, smoke, or fire is reported, set can_drive=false and clearly recommend stopping safely and seeking assistance.',
  'If the image is unclear or unrelated to the vehicle, state that in warnings and do not infer a fault from it.',
  'If the image is the only source and is unsuitable for analysis, return confidence=0 and do not assume a fault or part.',
].join(' ');

function normalizeLocale(locale) {
  return String(locale || '').toLowerCase() === 'en' ? 'en' : 'ar';
}

function buildDiagnosisPrompts({ car, description, obdContext, hasImage, schemaDescription, locale }) {
  const language = normalizeLocale(locale);
  const system = language === 'en'
    ? `You are an automotive diagnostic guidance assistant. Return JSON only according to the schema. ${SAFETY_INSTRUCTIONS_EN} The local OBD database is authoritative for known code definitions and must not be contradicted. An unknown local code is an unconfirmed possible interpretation. Write all user-facing explanations and recommendations in English while preserving JSON keys, DTC codes, numbers, units, and technical identifiers. Schema: ${schemaDescription}`
    : `أنت محلل أعطال سيارات إرشادي. أرجع JSON فقط حسب المخطط. ${SAFETY_INSTRUCTIONS} قاعدة OBD المحلية هي المرجع الملزم لتعريف الأكواد المعروفة ولا يجوز تغييرها. الكود غير المعروف محليًا تفسيره احتمال غير مؤكد. اكتب جميع الشروحات والتوصيات الظاهرة للمستخدم بالعربية مع الحفاظ على مفاتيح JSON ورموز DTC والأرقام والوحدات والمصطلحات الفنية. المخطط: ${schemaDescription}`;
  const prompt = JSON.stringify({
    vehicle: {
      make: car?.brand || car?.make || null,
      model: car?.model || null,
      year: car?.year || null,
    },
    symptoms: description || null,
    scanned_obd_codes: obdContext,
    image_attached: hasImage,
    response_locale: language,
    instruction: language === 'en'
      ? 'Analyze all available sources together in one result. Do not treat a missing source as evidence that the vehicle is safe.'
      : 'حلل جميع المصادر المتاحة معًا في نتيجة واحدة، ولا تعتبر غياب مصدر دليلًا على سلامة السيارة.',
  });
  return { system, prompt };
}

module.exports = { buildDiagnosisPrompts, normalizeLocale, SAFETY_INSTRUCTIONS, SAFETY_INSTRUCTIONS_EN };
