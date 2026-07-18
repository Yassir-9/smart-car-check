import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  static int _idFor(String reminderId) => reminderId.hashCode & 0x7FFFFFFF;

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) return;
    await cancelReminder(reminderId);

    final scheduledDate = tz.TZDateTime.from(
      DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'maintenance_reminders',
      'تذكيرات الصيانة',
      channelDescription: 'تنبيهات مواعيد الصيانة والوثائق الرسمية',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: _idFor(reminderId),
      title: 'تذكير صيانة',
      body: title,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _idFor(reminderId));
  }
}
