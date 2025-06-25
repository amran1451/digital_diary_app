enum DayFilter { any, workdays, weekends }

class CategorySettings {
  bool enabled;
  int intervalMinutes;
  int startHour;
  int endHour;
  DayFilter days;

  CategorySettings({
    required this.enabled,
    required this.intervalMinutes,
    required this.startHour,
    required this.endHour,
    this.days = DayFilter.any,
  });

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'interval': intervalMinutes,
    'start': startHour,
    'end': endHour,
    'days': days.index,
  };

  factory CategorySettings.fromMap(Map<String, dynamic> m) => CategorySettings(
    enabled: m['enabled'] ?? true,
    intervalMinutes: m['interval'] ?? 180,
    startHour: m['start'] ?? 9,
    endHour: m['end'] ?? 21,
    days: DayFilter.values[m['days'] ?? 0],
  );
}

class NotificationSettings {
  Map<String, CategorySettings> categories;

  NotificationSettings({required this.categories});

  Map<String, dynamic> toMap() => {
    'categories': categories.map((k, v) => MapEntry(k, v.toMap())),
  };

  factory NotificationSettings.defaultSettings() => NotificationSettings(
    categories: {
      'thought': CategorySettings(
          enabled: true,
          intervalMinutes: 180,
          startHour: 9,
          endHour: 21),
      'activity': CategorySettings(
          enabled: true,
          intervalMinutes: 180,
          startHour: 9,
          endHour: 21),
      'emotion': CategorySettings(
          enabled: true,
          intervalMinutes: 180,
          startHour: 9,
          endHour: 21),
      'flow': CategorySettings(
          enabled: true,
          intervalMinutes: 180,
          startHour: 9,
          endHour: 21),
    },
  );
}

