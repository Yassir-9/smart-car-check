const SAFETY_INSTRUCTIONS = [
  'افصل بوضوح بين البيانات المؤكدة التي قدمها المستخدم أو قاعدة OBD المحلية، والأسباب المحتملة، والفحوصات الموصى بها.',
  'لا تصف أي قطعة بأنها تالفة أو تؤكد تشخيصًا دون فحص مباشر يثبت ذلك.',
  'استخدم لغة احتمالية مثل: قد يكون، يرجح، يحتاج تحققًا.',
  'إذا ذُكرت لمبة زيت حمراء أو حرارة مرتفعة أو فقدان فرامل أو دخان أو حريق، اجعل can_drive=false وتوصية التوقف الآمن وطلب المساعدة واضحة.',
  'إذا كانت الصورة غير واضحة أو غير مرتبطة بالسيارة، صرّح بذلك في warnings ولا تستنتج عطلًا منها.',
  'إذا كانت الصورة هي المصدر الوحيد وكانت غير صالحة للتحليل، أرجع confidence=0 ولا تفترض عطلًا أو قطعة.',
].join(' ');

function buildDiagnosisPrompts({ car, description, obdContext, hasImage, schemaDescription }) {
  const system = `أنت محلل أعطال سيارات إرشادي. أرجع JSON فقط حسب المخطط. ${SAFETY_INSTRUCTIONS} قاعدة OBD المحلية هي المرجع الملزم لتعريف الأكواد المعروفة ولا يجوز تغييرها. الكود غير المعروف محليًا تفسيره احتمال غير مؤكد. المخطط: ${schemaDescription}`;
  const prompt = JSON.stringify({
    vehicle: {
      make: car?.brand || car?.make || null,
      model: car?.model || null,
      year: car?.year || null,
    },
    symptoms: description || null,
    scanned_obd_codes: obdContext,
    image_attached: hasImage,
    instruction: 'حلل جميع المصادر المتاحة معًا في نتيجة واحدة، ولا تعتبر غياب مصدر دليلًا على سلامة السيارة.',
  });
  return { system, prompt };
}

module.exports = { buildDiagnosisPrompts, SAFETY_INSTRUCTIONS };
