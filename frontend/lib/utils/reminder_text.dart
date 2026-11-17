import '../l10n/app_localizations.dart';

/// Whole calendar days from [now] to [dueDate], ignoring the time of day
/// (0 = today, 1 = tomorrow, negative = overdue). Using dates avoids the
/// "0 days" shown for tomorrow's reminder when less than 24 hours remain.
int reminderCalendarDays(DateTime dueDate, DateTime now) =>
    DateTime.utc(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;

/// "Today" / "Tomorrow" / "N days remaining" / "Overdue by N days".
String reminderStatusText(AppLocalizations l10n, DateTime dueDate, DateTime now) {
  final days = reminderCalendarDays(dueDate, now);
  if (days < 0) return l10n.overdueDays(-days);
  if (days == 0) return l10n.reminderToday;
  if (days == 1) return l10n.reminderTomorrow;
  return l10n.daysRemaining(days);
}
