import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_en.dart';
import 'package:car_ai_diagnosis/utils/reminder_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ar = AppLocalizationsAr();
  final en = AppLocalizationsEn();
  final now = DateTime(2026, 11, 17, 15, 30);

  test('calendar days ignore the time of day', () {
    expect(reminderCalendarDays(DateTime(2026, 11, 17, 9), now), 0);
    expect(reminderCalendarDays(DateTime(2026, 11, 17, 23, 59), now), 0);
    // less than 24h away but a different date: tomorrow, not "0 days"
    expect(reminderCalendarDays(DateTime(2026, 11, 18, 1), now), 1);
    expect(reminderCalendarDays(DateTime(2026, 11, 16, 23), now), -1);
    expect(reminderCalendarDays(DateTime(2026, 12, 17), now), 30);
  });

  test('Arabic: today, tomorrow, N days, overdue', () {
    expect(reminderStatusText(ar, DateTime(2026, 11, 17), now), 'اليوم');
    expect(reminderStatusText(ar, DateTime(2026, 11, 18), now), 'غداً');
    expect(reminderStatusText(ar, DateTime(2026, 11, 30), now), 'باقي 13 يوم');
    expect(reminderStatusText(ar, DateTime(2026, 11, 16), now), 'متأخر 1 يوم');
    final overdue = reminderStatusText(ar, DateTime(2025, 9, 22), now);
    expect(overdue, startsWith('متأخر '));
    expect(overdue, isNot(contains('-')));
  });

  test('English: today, tomorrow, N days, overdue', () {
    expect(reminderStatusText(en, DateTime(2026, 11, 17), now), 'Today');
    expect(reminderStatusText(en, DateTime(2026, 11, 18), now), 'Tomorrow');
    expect(reminderStatusText(en, DateTime(2026, 11, 30), now), '13 day(s) remaining');
    expect(reminderStatusText(en, DateTime(2026, 11, 10), now), 'Overdue by 7 day(s)');
  });

  test('month and year boundaries and DST-free counting', () {
    expect(reminderCalendarDays(DateTime(2027, 1, 1), DateTime(2026, 12, 31, 23, 59)), 1);
    expect(reminderCalendarDays(DateTime(2026, 3, 30), DateTime(2026, 3, 28, 12)), 2);
  });

  test('a completed reminder says Done, never Overdue (past, today or future)', () {
    final past = DateTime(2025, 9, 22); // 421 days ago
    expect(reminderStatusText(ar, past, now, isDone: true), 'تم');
    expect(reminderStatusText(en, past, now, isDone: true), 'Done');
    expect(reminderStatusText(ar, past, now, isDone: true), isNot(contains('متأخر')));
    expect(reminderStatusText(en, past, now, isDone: true), isNot(contains('Overdue')));
    expect(reminderStatusText(ar, DateTime(2026, 11, 30), now, isDone: true), 'تم');
    // not done: unchanged
    expect(reminderStatusText(ar, past, now), startsWith('متأخر '));
    expect(reminderStatusText(ar, past, now, isDone: false), startsWith('متأخر '));
    expect(reminderStatusText(en, DateTime(2026, 11, 17), now), 'Today');
  });
}
