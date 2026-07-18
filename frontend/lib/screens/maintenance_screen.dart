import 'package:flutter/material.dart';
import '../models/maintenance_reminder.dart';
import '../services/maintenance_service.dart';
import '../services/notification_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await MaintenanceService.loadReminders();
    setState(() {
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
          title: r.title,
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
        title: reminder.title,
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
    return Scaffold(
      appBar: AppBar(title: const Text('تنبيهات الصيانة الدورية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const Center(child: Text('لا توجد تنبيهات صيانة حالياً'))
              : ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    final now = DateTime.now();
                    final daysLeft = reminder.dueDate.difference(now).inDays;
                    final isOverdue = daysLeft < 0 && !reminder.isDone;
                    final isSoon = daysLeft >= 0 && daysLeft <= 7 && !reminder.isDone;

                    return Dismissible(
                      key: ValueKey(reminder.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteReminder(reminder),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: Icon(
                          reminder.isDone
                              ? Icons.check_circle
                              : isOverdue
                                  ? Icons.warning
                                  : isSoon
                                      ? Icons.notifications_active
                                      : Icons.event,
                          color: reminder.isDone
                              ? Colors.green
                              : isOverdue
                                  ? Colors.red
                                  : isSoon
                                      ? Colors.orange
                                      : null,
                        ),
                        title: Text(
                          reminder.title,
                          style: TextStyle(
                            decoration: reminder.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          isOverdue
                              ? 'متأخر منذ ${-daysLeft} يوم'
                              : 'باقي $daysLeft يوم${reminder.notes != null ? ' • ${reminder.notes}' : ''}',
                        ),
                        trailing: Checkbox(
                          value: reminder.isDone,
                          onChanged: (_) => _toggleDone(reminder),
                        ),
                      ),
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
    return AlertDialog(
      title: const Text('تنبيه صيانة جديد'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'نوع الصيانة (مثال: تغيير الزيت)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التاريخ: ${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  child: const Text('تغيير'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
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
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
