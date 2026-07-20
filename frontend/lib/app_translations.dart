import 'locale_notifier.dart';

class AppTranslations {
  static final Map<String, Map<String, String>> _values = {
    'ar': {
      'app_title': 'تشخيص السيارة الذكي',
      'login_title': 'تسجيل الدخول برقم الجوال',
      'otp_title': 'أدخل رمز التحقق',
      'otp_subtitle': 'أرسلنا رمز تحقق مكوّن من 6 أرقام إلى جوالك',
      'phone_label': 'رقم الجوال',
      'phone_hint': '05XXXXXXXX',
      'otp_label': 'رمز التحقق',
      'send_otp': 'إرسال رمز التحقق',
      'verify_otp': 'تأكيد الرمز',
      'change_phone': 'تغيير رقم الجوال',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
      'dark_mode': 'الوضع الليلي',
      'logout': 'تسجيل الخروج',
      'description_hint': 'مثال: صوت طقطقة عند الدوران يمين',
      'diagnose_button': 'شخّص المشكلة',
      'new_diagnosis': 'بدء تشخيص جديد',
      'attach_warning_light': 'أضف صورة للمبة التحذير (اختياري)',
      'preferences': 'التفضيلات',
      'manage_cars': 'إدارة سياراتي',
      'about_app': 'عن التطبيق',
      'app_description':
          'تطبيق يستخدم الذكاء الاصطناعي لتقديم تشخيص أولي توجيهي لمشاكل السيارات بناءً على وصف المستخدم وبيانات السيارة.',
      'version': 'الإصدار 1.0.0',
      'disclaimer_text':
          'هذا التشخيص أولي وتوجيهي فقط، ولا يغني عن فحص فني معتمد من ورشة متخصصة قبل اتخاذ أي قرار يخص السلامة.',
    },
    'en': {
      'app_title': 'Smart Car Diagnosis',
      'login_title': 'Sign in with phone number',
      'otp_title': 'Enter verification code',
      'otp_subtitle': 'We sent a 6-digit code to your phone',
      'phone_label': 'Phone number',
      'phone_hint': '05XXXXXXXX',
      'otp_label': 'Verification code',
      'send_otp': 'Send verification code',
      'verify_otp': 'Verify code',
      'change_phone': 'Change phone number',
      'settings': 'Settings',
      'language': 'Language',
      'arabic': 'العربية',
      'english': 'English',
      'dark_mode': 'Dark mode',
      'logout': 'Log out',
      'description_hint': 'Example: clicking sound when turning right',
      'diagnose_button': 'Diagnose problem',
      'new_diagnosis': 'Start new diagnosis',
      'attach_warning_light': 'Add warning light photo (optional)',
      'preferences': 'Preferences',
      'manage_cars': 'Manage my cars',
      'about_app': 'About the app',
      'app_description':
          'An app that uses AI to provide an initial guiding diagnosis for car problems based on the user\'s description and car data.',
      'version': 'Version 1.0.0',
      'disclaimer_text':
          'This is an initial guiding diagnosis only, and does not replace a certified technical inspection at a specialized workshop before making any safety-related decision.',
    },
  };

  static String t(String key) {
    final lang = localeNotifier.value;
    return _values[lang]?[key] ?? _values['ar']?[key] ?? key;
  }
}
