import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PersonalDebtReminderService {
  PersonalDebtReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  static Future<void> schedule({
    required int itemId,
    required String person,
    required bool lent,
    required DateTime dueDate,
    required int amountPaise,
  }) async {
    await initialize();
    if (kIsWeb) return;
    await cancel(itemId);
    final scheduled = tz.TZDateTime.from(
        DateTime(dueDate.year, dueDate.month, dueDate.day, 9), tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      itemId,
      lent ? 'Interest due from $person' : 'Interest due to $person',
      'Reminder: ₹${(amountPaise / 100).toStringAsFixed(amountPaise % 100 == 0 ? 0 : 2)}',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'personal_debt_interest',
          'Personal debt interest reminders',
          channelDescription:
              'Reminders for interest due on lent or borrowed money',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int itemId) async {
    if (kIsWeb) return;
    await _plugin.cancel(itemId);
  }
}
