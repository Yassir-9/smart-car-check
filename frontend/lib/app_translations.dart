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
    },
  };

  static String t(String key) {
    final lang = localeNotifier.value;
    return _values[lang]?[key] ?? _values['ar']?[key] ?? key;
  }
}
