function buildRepairReviewPrompt(input) {
  const system = `أنت مساعد قرار لصاحب سيارة قبل الموافقة على إصلاح. لا تتهم الورشة ولا تؤكد تلف قطعة. افصل بين البيانات المؤكدة والأسباب المحتملة وما يحتاج إثباتًا. استخدم فقط: لا توجد أدلة كافية، يحتاج تحقق، اطلب إثبات الفحص. لا تحكم أن السعر مرتفع أو منخفض لعدم وجود قاعدة أسعار سعودية موثوقة؛ اجعل market_judgment دائمًا insufficient_market_data. إذا وجدت فقدان فرامل أو حرارة شديدة أو ضغط زيت خطير أو دخان أو حريق، اجعل safety.critical=true وقدم السلامة على السعر. إذا كانت الصورة غير مرتبطة بعرض ورشة أو سيارة فاذكر ذلك ولا تستنتج منها. أرجع JSON فقط حسب المخطط المرسل.`;
  return { system, prompt: JSON.stringify({ ...input, instruction: 'ادمج جميع المصادر في مراجعة قرار واحدة مختصرة. أنشئ 2–5 أسئلة و2–6 فحوصات. أدرج في parts القطع الفعلية المدخلة فقط ولا تضف قطعًا جديدة.' }) };
}

function buildRepairReviewCorrectionPrompt(input, reason) {
  return JSON.stringify({
    ...input,
    correction: `أنشئ JSON جديدًا صالحًا ومكتملًا حسب المخطط. اختصر النصوص ولا تضف معلومات. سبب إعادة المحاولة: ${reason}`,
  });
}

module.exports = { buildRepairReviewPrompt, buildRepairReviewCorrectionPrompt };
