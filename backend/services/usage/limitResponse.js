// 402 body used when a free monthly limit is reached. Same code and shape for
// diagnoses and quote reviews, so the existing app handles both the same way.
const { nextMonthStartIso } = require('../../config/limits');

function limitReachedBody(locale, limit, kind = 'diagnosis') {
  const en = locale === 'en';
  const message = kind === 'quote_review'
    ? (en
      ? "You have reached this month's free limit for quote reviews. It renews at the start of next month."
      : 'وصلت إلى الحد الشهري المجاني لمراجعة العروض. يتجدد في بداية الشهر القادم.')
    : (en
      ? "You have reached this month's free diagnosis limit. It renews at the start of next month."
      : 'وصلت إلى الحد الشهري للتشخيصات المجانية. يتجدد في بداية الشهر القادم.');
  return {
    code: 'FREE_DIAGNOSIS_LIMIT_REACHED',
    error: message,
    subscriptionRequired: false,
    freeUsageLimit: limit,
    limitResetsAt: nextMonthStartIso(),
  };
}

module.exports = { limitReachedBody };
