import '../models/car_model.dart';
import '../services/car_service.dart';
import '../utils/reminder_text.dart';
import '../utils/reminder_title.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/maintenance_reminder.dart';
import '../services/maintenance_service.dart';
import '../services/notification_service.dart';
import '../theme/app_design_system.dart' hide StatusChip;
import '../theme/app_tokens.dart';
import '../widgets/ui/ui.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceReminder> _reminders = [];
  List<CarModel> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  String _displayTitle(MaintenanceReminder r) => reminderDisplayTitle(
      l10n: AppLocalizations.of(context),
      languageCode: Localizations.localeOf(context).languageCode,
      reminder: r,
      cars: _cars);

  Future<void> _loadReminders() async {
    final reminders = await MaintenanceService.loadReminders();
    final cars = await CarService.loadCars();
    setState(() {
      _cars = cars;
      _reminders = reminders;
      _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      _loading = false;
    });
    for (final r in _reminders) {
      if (r.isDone) {
        await NotificationService.cancelReminder(r.id);
      } else {
        await NotificationService.scheduleReminder(
          reminderId: r.id,
          title: _displayTitle(r),
          dueDate: r.dueDate,
        );
      }
    }
  }

  Future<void> _saveReminders() async {
    await MaintenanceService.saveReminders(_reminders);
  }

  Future<void> _addReminder() async {
    final result = await showDialog<MaintenanceReminder>(
      context: context,
      builder: (context) => const _AddReminderDialog(),
    );
    if (result != null) {
      setState(() {
        _reminders.add(result);
        _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      });
      await _saveReminders();
      await NotificationService.scheduleReminder(
        reminderId: result.id,
        title: result.title,
        dueDate: result.dueDate,
      );
    }
  }

  Future<void> _toggleDone(MaintenanceReminder reminder) async {
    final newIsDone = !reminder.isDone;
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder.copyWith(isDone: newIsDone);
      }
    });
    await _saveReminders();
    if (newIsDone) {
      await NotificationService.cancelReminder(reminder.id);
    } else {
      await NotificationService.scheduleReminder(
        reminderId: reminder.id,
        title: _displayTitle(reminder),
        dueDate: reminder.dueDate,
      );
    }
  }

  Future<void> _deleteReminder(MaintenanceReminder reminder) async {
    setState(() {
      _reminders.removeWhere((r) => r.id == reminder.id);
    });
    await _saveReminders();
    await NotificationService.cancelReminder(reminder.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.maintenanceReminders)),
      body: _loading
          ? AppStateView(
              icon: Icons.event_outlined,
              title: l10n.loadingMaintenanceReminders,
              loading: true)
          : _reminders.isEmpty
              ? AppStateView(
                  icon: Icons.event_available_outlined,
                  title: l10n.noMaintenanceReminders,
                  message: l10n.noMaintenanceRemindersMessage,
                  actionLabel: l10n.addReminder,
                  onAction: _addReminder)
              : ListView.builder(
                  // Bottom space keeps the floating button off the last card.
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.md, AppSpacing.md, Ui.listBottomInset),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    final now = DateTime.now();
                    final daysLeft =
                        reminderCalendarDays(reminder.dueDate, now);
                    final isOverdue = daysLeft < 0 && !reminder.isDone;
                    final isSoon =
                        daysLeft >= 0 && daysLeft <= 14 && !reminder.isDone;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                          child: Dismissible(
                        key: ValueKey(reminder.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteReminder(reminder),
                        background: Container(
                          color: Ui.dangerText,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          leading: IconTile(
                            reminder.isDone
                                ? Icons.check_circle_outline
                                : isOverdue
                                    ? Icons.warning_amber_rounded
                                    : isSoon
                                        ? Icons.notifications_active_outlined
                                        : Icons.event_outlined,
                            size: 44,
                            color: reminder.isDone
                                ? Ui.okText
                                : isOverdue
                                    ? Ui.dangerText
                                    : isSoon
                                        ? Ui.warnText
                                        : Ui.primaryText,
                          ),
                          title: Text(
                            _displayTitle(reminder),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: reminder.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: Ui.s4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip(
                                  label: reminderStatusText(
                                      l10n, reminder.dueDate, now,
                                      isDone: reminder.isDone),
                                  level: reminderChipLevel(daysLeft,
                                      isDone: reminder.isDone),
                                  icon: reminder.isDone ? null : Icons.schedule,
                                ),
                                if (reminder.notes != null &&
                                    !(daysLeft < 0 && !reminder.isDone))
                                  Padding(
                                    padding: const EdgeInsets.only(top: Ui.s4),
                                    child: Text(reminder.notes!,
                                        style: const TextStyle(
                                            fontSize: Ui.secondary,
                                            color: Ui.textSecondary)),
                                  ),
                              ],
                            ),
                          ),
                          trailing: Checkbox(
                            value: reminder.isDone,
                            onChanged: (_) => _toggleDone(reminder),
                          ),
                        ),
                      )),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  const _AddReminderDialog();

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newMaintenanceReminder),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.maintenanceTypeExample,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.notesOptional),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dateLabel(
                      '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  child: Text(l10n.change),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              MaintenanceReminder(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text.trim(),
                dueDate: _dueDate,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
