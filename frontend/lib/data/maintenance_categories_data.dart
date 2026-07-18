class MaintenanceCategoriesData {
  // كل قيمة تمثل عدد الأيام التقريبي حتى موعد الصيانة القادمة
  static const Map<String, int> intervalDays = {
    'تغيير زيت المحرك': 180,
    'فلتر الزيت': 180,
    'فلتر الهواء': 365,
    'البواجي': 730,
    'فحمات الفرامل (تيل الفرامل)': 365,
    'البطارية': 1095,
    'الكفرات (الإطارات)': 730,
    'فلتر المكيف': 365,
    'سائل الفرامل': 730,
    'أخرى': 0,
  };

  static List<String> get categories => intervalDays.keys.toList();

  static bool hasAutoReminder(String category) {
    return (intervalDays[category] ?? 0) > 0;
  }
}
