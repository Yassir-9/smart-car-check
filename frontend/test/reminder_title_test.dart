import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_en.dart';
import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/models/maintenance_reminder.dart';
import 'package:car_ai_diagnosis/utils/reminder_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ar = AppLocalizationsAr();
  final en = AppLocalizationsEn();
  final nissan = CarModel(id: 'c1', brand: 'نيسان', model: 'ماكسيما', year: 2016);
  final cars = [nissan];
  final due = DateTime(2026, 12, 1);

  String show(AppLocalizations l, String lang, MaintenanceReminder r) =>
      reminderDisplayTitle(l10n: l, languageCode: lang, reminder: r, cars: cars);

  test('generated expiry reminders follow the current language, not the saved one', () {
    final saved = MaintenanceReminder(id: 'c1_registration', title: 'Registration expiry - Nissan Maxima - 2016', dueDate: due);
    expect(show(ar, 'ar', saved), startsWith('انتهاء الاستمارة - '));
    expect(show(ar, 'ar', saved), isNot(contains('Registration')));
    expect(show(en, 'en', saved), startsWith('Registration expiry - '));
    for (final (suffix, arText, enText) in [
      ('insurance', 'انتهاء التأمين', 'Insurance expiry'),
      ('inspection', 'انتهاء الفحص الدوري', 'Inspection expiry'),
    ]) {
      final r = MaintenanceReminder(id: 'c1_$suffix', title: 'x', dueDate: due);
      expect(show(ar, 'ar', r), startsWith('$arText - '));
      expect(show(en, 'en', r), startsWith('$enText - '));
    }
  });

  test('reminders typed by the user are never changed', () {
    final mine = MaintenanceReminder(id: '1731800000000', title: 'تغيير زيت', dueDate: due);
    expect(show(ar, 'ar', mine), 'تغيير زيت');
    expect(show(en, 'en', mine), 'تغيير زيت');
    final english = MaintenanceReminder(id: '17318', title: 'Change oil', dueDate: due);
    expect(show(ar, 'ar', english), 'Change oil');
  });

  test('a generated reminder of an unknown (deleted) car keeps its stored title', () {
    final orphan = MaintenanceReminder(id: 'gone_insurance', title: 'Insurance expiry - Old car', dueDate: due);
    expect(show(ar, 'ar', orphan), 'Insurance expiry - Old car');
  });
}
