import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PersonalDebtReminderService {
  PersonalDebtReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // A reminder problem must never stop a record from being saved.
  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await _initialize();
    } catch (e) {
      debugPrint('Reminder setup failed: $e');
    }
  }

  static Future<void> _initialize() async {
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
    if (kIsWeb || !_initialized) return;
    await cancel(itemId);
    try {
      await _schedule(itemId, person, lent, dueDate, amountPaise);
    } catch (e) {
      debugPrint('Could not schedule reminder: $e');
    }
  }

  static Future<void> _schedule(int itemId, String person, bool lent,
      DateTime dueDate, int amountPaise) async {
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
    try {
      await _plugin.cancel(itemId);
    } catch (e) {
      debugPrint('Could not cancel reminder: $e');
    }
  }
}
