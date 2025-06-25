import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/entry_data.dart';
import 'local_db.dart';
import '../models/notification_log_item.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: _onNotificationResponse);
    await Permission.notification.request();
  }

  static Future<void> scheduleDailyNotifications() async {
    final questions = {
      'thought': 'О чём ты сейчас думаешь?',
      'activity': 'Чем занят?',
      'emotion': 'Что чувствуешь?',
      'flow': 'Как день идёт?'
    };
    int id = 0;
    for (final entry in questions.entries) {
      final hour = 9 + id * 3; // 9, 12, 15, 18
      await _plugin.zonedSchedule(
        id++,
        'Дневник',
        entry.value,
        _nextInstanceOfHour(hour),
        const NotificationDetails(
            android: AndroidNotificationDetails('diary', 'Diary')),
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: entry.key,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _onNotificationResponse(
      NotificationResponse response) async {
    final type = response.payload;
    if (type == null) return;
    // Create or load today's entry
    final date = _todayStr();
    var entry = await LocalDb.getByDate(date);
    entry ??= EntryData(date: date, time: _nowStr());
    entry.notificationsLog.add(NotificationLogItem(
        type: type, time: _nowStr(), text: ''));
    await LocalDb.saveOrUpdate(entry);
  }

  static String _todayStr() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.day)}-${two(now.month)}-${now.year}';
  }

  static String _nowStr() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}';
  }
}