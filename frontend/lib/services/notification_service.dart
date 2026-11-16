import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (!_isSupportedPlatform) return;
    tzdata.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: initSettings);

    if (_isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  static int _idFor(String reminderId) => reminderId.hashCode & 0x7FFFFFFF;
  static int deterministicReminderId(String repairId) => _idFor('repair-verification-$repairId');

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (!_isSupportedPlatform) return;
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
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _idFor(reminderId),
      title: 'تذكير صيانة',
      body: title,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      // Reminders are day-level (09:00); inexact scheduling needs no exact-alarm
      // permission and avoids the SCHEDULE_EXACT_ALARM Play policy declaration.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleRepairVerificationReminder({
    required String repairId,
    int days = 3,
  }) =>
      scheduleReminder(
        reminderId: 'repair-verification-$repairId',
        title: 'هل اختفت المشكلة بعد الإصلاح؟ افتح Smart Car Check للتحقق.',
        dueDate: DateTime.now().add(Duration(days: days)),
      );

  static Future<void> cancelReminder(String reminderId) async {
    if (!_isSupportedPlatform) return;
    await _plugin.cancel(id: _idFor(reminderId));
  }

  static Future<void> cancelRepairVerificationReminder(String repairId) =>
      cancelReminder('repair-verification-$repairId');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
