import 'dart:convert';

import 'notification_log_item.dart';

class EntryData {
  /// ID документа в Firestore (не используем в этом варианте)
  final String? id;
  /// локальный ID (rowid) в SQLite
  int? localId;

  String date;
  String time;
  /// Место, где была сделана запись
  String place;
  final DateTime createdAt;

  String rating;
  String ratingReason;
  String bedTime;
  String wakeTime;
  String sleepDuration;
  String steps;
  String activity;
  String energy;
  String? wellBeing;
  String mood;
  String mainEmotions;
  String influence;
  String important;
  String tasks;
  String notDone;
  String thought;
  String development;
  String qualities;
  String growthImprove;
  String pleasant;
  String tomorrowImprove;
  String stepGoal;
  String flow;
  /// Исходный текст записи
  String raw;
  /// Ручные заметки/планы для дня (до 3 строк)
  String highlights;
  /// Нужно ли ещё отправить в Telegram
  bool needsSync;
  /// Ответы на уведомления в течение дня
  List<NotificationLogItem> notificationsLog;

  EntryData({
    this.id,
    this.localId,
    required this.date,
    required this.time,
    this.place = '',
    DateTime? createdAt,
    this.rating = '',
    this.ratingReason = '',
    this.bedTime = '',
    this.wakeTime = '',
    this.sleepDuration = '',
    this.steps = '',
    this.activity = '',
    this.energy = '',
    this.wellBeing = '',
    this.mood = '',
    this.mainEmotions = '',
    this.influence = '',
    this.important = '',
    this.tasks = '',
    this.notDone = '',
    this.thought = '',
    this.development = '',
    this.qualities = '',
    this.growthImprove = '',
    this.pleasant = '',
    this.tomorrowImprove = '',
    this.stepGoal = '',
    this.flow = '',
    this.raw = '',
    this.needsSync = true,
    this.highlights = '',
    List<NotificationLogItem>? notificationsLog,
  })  : notificationsLog = notificationsLog ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'date': date,
        'time': time,
        'place': place,
        'createdAt': createdAt.toIso8601String(),
        'rating': rating,
        'ratingReason': ratingReason,
        'bedTime': bedTime,
        'wakeTime': wakeTime,
        'sleepDuration': sleepDuration,
        'steps': steps,
        'activity': activity,
        'energy': energy,
        'wellBeing': wellBeing,
        'mood': mood,
        'mainEmotions': mainEmotions,
        'influence': influence,
        'important': important,
        'tasks': tasks,
        'notDone': notDone,
        'thought': thought,
        'development': development,
        'qualities': qualities,
        'growthImprove': growthImprove,
        'pleasant': pleasant,
        'tomorrowImprove': tomorrowImprove,
        'stepGoal': stepGoal,
        'flow': flow,
        'highlights': highlights,
        'raw': raw,
        'needsSync': needsSync ? 1 : 0,
        'notificationsLog': jsonEncode(notificationsLog.map((e) => e.toMap()).toList()),
      };

  factory EntryData.fromMap(Map<String, dynamic> m, {String? id}) {
    DateTime _parseFallbackDate() {
      final ds = m['date']?.toString() ?? '';
      final ts = m['time']?.toString() ?? '';
      try {
        final dMatch = RegExp(r'^(\d{1,2})[.\-](\d{1,2})[.\-](\d{2,4})').firstMatch(ds);
        if (dMatch != null) {
          final day = int.parse(dMatch.group(1)!);
          final month = int.parse(dMatch.group(2)!);
          final year = int.parse(dMatch.group(3)!);
          int h = 0, m = 0;
          final tMatch = RegExp(r'^(\d{1,2}):(\d{1,2})').firstMatch(ts);
          if (tMatch != null) {
            h = int.parse(tMatch.group(1)!);
            m = int.parse(tMatch.group(2)!);
          }
          return DateTime(year, month, day, h, m);
        }
      } catch (_) {}
      return DateTime.now();
    }

    final created = m['createdAt'] as String?;
    final createdAt = (created != null && created.isNotEmpty)
        ? DateTime.parse(created).toLocal()
        : _parseFallbackDate();
    return EntryData(
      id: id,
      localId: m['id'] as int?,
      date: m['date'] ?? '',
      time: m['time'] ?? '',
      place: m['place'] ?? '',
      createdAt: createdAt,
      raw: m['raw'] ?? '',
      rating: m['rating'] ?? '',
      ratingReason: m['ratingReason'] ?? '',
      bedTime: m['bedTime'] ?? '',
      wakeTime: m['wakeTime'] ?? '',
      sleepDuration: m['sleepDuration'] ?? '',
      steps: m['steps'] ?? '',
      activity: m['activity'] ?? '',
      energy: m['energy'] ?? '',
      wellBeing: m['wellBeing'] as String?,
      mood: m['mood'] ?? '',
      mainEmotions: m['mainEmotions'] ?? '',
      influence: m['influence'] ?? '',
      important: m['important'] ?? '',
      tasks: m['tasks'] ?? '',
      notDone: m['notDone'] ?? '',
      thought: m['thought'] ?? '',
      development: m['development'] ?? '',
      qualities: m['qualities'] ?? '',
      growthImprove: m['growthImprove'] ?? '',
      pleasant: m['pleasant'] ?? '',
      tomorrowImprove: m['tomorrowImprove'] ?? '',
      stepGoal: m['stepGoal'] ?? '',
      flow: m['flow'] ?? '',
      needsSync: (m['needsSync'] as int? ?? 1) == 1,
      highlights: m['highlights'] ?? '',
      notificationsLog: (m['notificationsLog'] != null && m['notificationsLog'].toString().isNotEmpty)
          ? List<Map<String, dynamic>>.from(jsonDecode(m['notificationsLog']))
          .map((n) => NotificationLogItem.fromMap(n))
          .toList()
          : [],
    );
  }

  String get createdAtFormatted =>
      '${createdAt.day.toString().padLeft(2, '0')}-'
      '${createdAt.month.toString().padLeft(2, '0')}-'
      '${createdAt.year} '
      '${createdAt.hour.toString().padLeft(2, '0')}:' 
      '${createdAt.minute.toString().padLeft(2, '0')}';
}
