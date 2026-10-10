const messages = {
  PART_FIELDS_REQUIRED: {
    ar: 'اسم القطعة والشركة ورقم الجوال مطلوبة',
    en: 'Part name, vehicle brand, and phone number are required',
  },
  PART_NOT_FOUND: { ar: 'القطعة غير موجودة', en: 'Part not found' },
  PART_DELETE_FORBIDDEN: {
    ar: 'لا تملك صلاحية حذف هذه القطعة',
    en: 'You do not have permission to delete this listing',
  },
  PART_UPDATE_FORBIDDEN: {
    ar: 'لا تملك صلاحية تعديل هذه القطعة',
    en: 'You do not have permission to update this listing',
  },
  PART_READ_FORBIDDEN: {
    ar: 'لا تملك صلاحية عرض بيانات هذه القطعة',
    en: 'You do not have permission to view this listing data',
  },
  PART_CONTACT_UNAVAILABLE: {
    ar: 'بيانات التواصل غير متاحة',
    en: 'Seller contact information is unavailable',
  },
  EMPTY_CART: { ar: 'السلة فاضية', en: 'The cart is empty' },
  OWN_PART_PURCHASE: {
    ar: 'لا يمكنك شراء قطعتك الخاصة',
    en: 'You cannot purchase your own listing',
  },
  NO_VALID_PARTS: {
    ar: 'لا توجد قطع صالحة للشراء بالسلة',
    en: 'The cart contains no valid purchasable parts',
  },
  INVALID_PLAN: { ar: 'باقة غير صحيحة', en: 'Invalid subscription plan' },
  PAYMENT_CREATION_FAILED: {
    ar: 'تعذر إنشاء فاتورة الدفع',
    en: 'Could not create the payment invoice',
  },
  SELF_RATING: { ar: 'لا يمكنك تقييم نفسك', en: 'You cannot rate yourself' },
  INVALID_RATING: {
    ar: 'التقييم يجب أن يكون بين 1 و5',
    en: 'Rating must be between 1 and 5',
  },
  INTERNAL_ERROR: {
    ar: 'حدث خطأ، حاول مرة أخرى',
    en: 'An error occurred. Try again.',
  },
};

function requestLocale(req) {
  const value = req.body?.locale || req.get?.('X-App-Locale') || req.query?.locale;
  return typeof value === 'string' && value.toLowerCase().startsWith('en')
    ? 'en'
    : 'ar';
}

function localizedError(req, code) {
  const locale = requestLocale(req);
  const entry = messages[code] || messages.INTERNAL_ERROR;
  return { code, error: entry[locale] || entry.ar };
}

function localizedPaymentSuccess(req, kind) {
  const locale = requestLocale(req);
  const isEnglish = locale === 'en';
  return {
    locale,
    direction: isEnglish ? 'ltr' : 'rtl',
    title: isEnglish ? 'Payment completed successfully!' : 'تم الدفع بنجاح!',
    body: kind === 'subscription'
      ? (isEnglish
          ? 'You can now return to the app and enjoy your subscription.'
          : 'يمكنك الآن الرجوع للتطبيق والاستمتاع بالاشتراك.')
      : (isEnglish
          ? 'You can now return to the app and follow your order.'
          : 'يمكنك الآن الرجوع للتطبيق ومتابعة طلبك.'),
  };
}

module.exports = { requestLocale, localizedError, localizedPaymentSuccess };
