import '../l10n/app_localizations.dart';
import '../widgets/ui/status_chip.dart';

/// Chip colour of a reminder: green is only for a completed one. Pending ones
/// go grey (more than 14 days away), amber (today up to 14 days) or red
/// (overdue).
StatusLevel reminderChipLevel(int daysLeft, {required bool isDone}) {
  if (isDone) return StatusLevel.ok;
  if (daysLeft < 0) return StatusLevel.danger;
  if (daysLeft <= 14) return StatusLevel.warn;
  return StatusLevel.neutral;
}

/// Whole calendar days from [now] to [dueDate], ignoring the time of day
/// (0 = today, 1 = tomorrow, negative = overdue). Using dates avoids the
/// "0 days" shown for tomorrow's reminder when less than 24 hours remain.
int reminderCalendarDays(DateTime dueDate, DateTime now) =>
    DateTime.utc(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;

/// "Today" / "Tomorrow" / "N days remaining" / "Overdue by N days".
/// A completed reminder is never "overdue": it just says "Done".
String reminderStatusText(AppLocalizations l10n, DateTime dueDate, DateTime now,
    {bool isDone = false}) {
  if (isDone) return l10n.reminderDone;
  final days = reminderCalendarDays(dueDate, now);
  if (days < 0) return l10n.overdueDays(-days);
  if (days == 0) return l10n.reminderToday;
  if (days == 1) return l10n.reminderTomorrow;
  return l10n.daysRemaining(days);
}
