import '../l10n/app_localizations.dart';
import '../models/maintenance_reminder.dart';
import '../models/vehicle_issue.dart';

/// Number of reminders that are not done yet. Reminders are not stored per car
/// (MaintenanceReminder has no car id), so this counts all of the user's.
int upcomingReminderCount(List<MaintenanceReminder> reminders) =>
    reminders.where((r) => !r.isDone).length;

/// Open faults of the issues list (already loaded for the current car). The
/// "not resolved" field is `status`: everything except 'repaired' is open (the
/// same rule the home screen uses for "Unresolved issues").
int openIssueCount(List<VehicleIssue> issues) =>
    issues.where((i) => i.status != 'repaired').length;

/// Whole calendar days between [date] and [now] (0 = today, 1 = yesterday).
/// Negative values (a date in the future) are treated as today.
int daysSince(DateTime date, DateTime now) {
  final a = DateTime.utc(date.year, date.month, date.day);
  final b = DateTime.utc(now.year, now.month, now.day);
  final days = b.difference(a).inDays;
  return days < 0 ? 0 : days;
}

/// "Today", "Yesterday" or "N days ago" in the UI language.
String relativeDayText(AppLocalizations l10n, DateTime date, DateTime now) {
  final days = daysSince(date.toLocal(), now);
  if (days == 0) return l10n.relativeToday;
  if (days == 1) return l10n.relativeYesterday;
  return l10n.relativeDaysAgo(days);
}
