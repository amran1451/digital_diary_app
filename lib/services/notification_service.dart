import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/entry_data.dart';
import '../models/notification_log_item.dart';
import '../models/notification_settings.dart';
import '../app_config.dart';
import 'local_db.dart';
import 'draft_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _questions = <String, String>{
    'thought': 'О чём ты сейчас думаешь?',
    'activity': 'Чем занят?',
    'emotion': 'Что чувствуешь?',
    'flow': 'Как день идёт?'
  };
  static late NotificationSettings settings;
  static final Map<String, bool> _pending = {
    'thought': false,
    'activity': false,
    'emotion': false,
    'flow': false,
  };

  static Future<void> init() async {
    settings = await loadSettings();
    if (!notificationsEnabled) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    await _restorePending();
    await scheduleAll();
  }

  static Future<void> requestPermission() async {
    if (!notificationsEnabled) return;
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        // Permission denied - notifications will remain disabled
        return;
      }
      // Reschedule notifications after permission granted
      await scheduleAll();
    } catch (e) {
      // Log and ignore to avoid crash
      debugPrint('Notification permission error: $e');
    }
  }

  static Future<void> updateSettings(NotificationSettings newSettings) async {
    settings = newSettings;
    await _saveSettings(settings);
    if (!notificationsEnabled) return;
    await cancelAll();
    await scheduleAll();
  }

  static Future<void> cancelAll() async {
    if (!notificationsEnabled) return;
    for (final id in [0, 1, 2, 3]) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> scheduleAll() async {
    if (!notificationsEnabled) return;
    int id = 0;
    for (final cat in _questions.keys) {
      if (settings.categories[cat]?.enabled ?? false) {
        if (!_pending[cat]!) {
          await _scheduleNext(cat, id);
        }
      } else {
        await _plugin.cancel(id);
      }
      id++;
    }
  }

  static Future<void> _scheduleNext(String cat, int id) async {
    if (!notificationsEnabled) return;
    final cs = settings.categories[cat]!;
    final now = tz.TZDateTime.now(tz.local);
    var next = now.add(Duration(minutes: cs.intervalMinutes));
    while (true) {
      if (next.hour >= cs.endHour) {
        next = tz.TZDateTime(tz.local, next.year, next.month, next.day)
            .add(const Duration(days: 1));
        next = tz.TZDateTime(tz.local, next.year, next.month, next.day, cs.startHour);
      }
      if (next.hour < cs.startHour) {
        next = tz.TZDateTime(tz.local, next.year, next.month, next.day, cs.startHour);
      }
      if (!_dayAllowed(next, cs.days)) {
        next = next.add(const Duration(days: 1));
        next = tz.TZDateTime(tz.local, next.year, next.month, next.day, cs.startHour);
        continue;
      }
      if (next.isBefore(now)) {
        next = next.add(Duration(minutes: cs.intervalMinutes));
        continue;
      }
      break;
    }
    final question = _questions[cat]!;
    await _plugin.zonedSchedule(
      id,
      'Дневник',
      question,
      next,
      const NotificationDetails(android: AndroidNotificationDetails('diary', 'Diary')),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({'cat': cat, 'time': next.toIso8601String()}),
    );
    await _setPending(cat, true);
    await _logSent(cat, next);
  }

  static bool _dayAllowed(tz.TZDateTime dt, DayFilter filter) {
    if (filter == DayFilter.any) return true;
    if (filter == DayFilter.workdays) return dt.weekday <= 5;
    return dt.weekday >= 6;
  }

  static Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (!notificationsEnabled) return;
    if (response.payload == null) return;
    final data = jsonDecode(response.payload!);
    final cat = data['cat'] as String?;
    final timeIso = data['time'] as String?;
    if (cat == null || timeIso == null) return;
    final sent = DateTime.parse(timeIso).toLocal();
    await _setPending(cat, false);

    final dateStr = _dateStr(sent);
    var entry = await LocalDb.getByDate(dateStr);

    // Try to use draft if it matches today's entry
    final draft = await DraftService.loadDraft();
    if (draft != null && draft.date == dateStr) {
      entry = draft;
    }

    entry ??= EntryData(date: dateStr, time: _timeStr(sent));
    for (final n in entry.notificationsLog) {
      if (n.type == cat && n.sentTime == _timeStr(sent)) {
        entry.notificationsLog.remove(n);
        break;
      }
    }
    entry.notificationsLog.add(NotificationLogItem(
      type: cat,
      sentTime: _timeStr(sent),
      answerTime: _nowStr(),
      text: response.input ?? '',
    ));

    if (draft != null && draft.date == dateStr) {
      DraftService.currentDraft = entry;
      await DraftService.saveDraft();
    } else {
      await LocalDb.saveOrUpdate(entry);
    }
    await _scheduleNext(cat, _questions.keys.toList().indexOf(cat));
  }

  static Future<void> _logSent(String cat, tz.TZDateTime when) async {
    if (!notificationsEnabled) return;
    final dateStr = _dateStr(when);
    var entry = await LocalDb.getByDate(dateStr);

    final draft = await DraftService.loadDraft();
    if (draft != null && draft.date == dateStr) {
      entry = draft;
    }

    entry ??= EntryData(date: dateStr, time: _timeStr(when));
    entry.notificationsLog.add(NotificationLogItem(
      type: cat,
      sentTime: _timeStr(when),
      answerTime: '',
      text: '',
    ));
    if (draft != null && draft.date == dateStr) {
      DraftService.currentDraft = entry;
      await DraftService.saveDraft();
    } else {
      await LocalDb.saveOrUpdate(entry);
    }
  }

  static Future<void> _restorePending() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _pending.keys) {
      _pending[key] = prefs.getBool('pending_$key') ?? false;
    }
  }

  static Future<void> _setPending(String cat, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _pending[cat] = value;
    await prefs.setBool('pending_$cat', value);
  }

  static Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('notification_settings');
    if (str == null) return NotificationSettings.defaultSettings();
    final map = jsonDecode(str) as Map<String, dynamic>;
    final cats = (map['categories'] as Map<String, dynamic>).map((k, v) =>
        MapEntry(k, CategorySettings.fromMap(Map<String, dynamic>.from(v))));
    return NotificationSettings(categories: cats);
  }

  static Future<void> _saveSettings(NotificationSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_settings', jsonEncode(s.toMap()));
  }

  static String _dateStr(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}-${two(dt.month)}-${dt.year}';
  }

  static String _timeStr(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  static String _nowStr() => _timeStr(DateTime.now());
}