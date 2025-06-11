class EntryData {
  /// ID документа в Firestore (не используем в этом варианте)
  final String? id;
  /// локальный ID (rowid) в SQLite
  int? localId;

  String date;
  String time;
  final DateTime createdAt;

  String rating;
  String ratingReason;
  String bedTime;
  String wakeTime;
  String sleepDuration;
  String steps;
  String activity;
  String energy;
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

  /// Нужно ли ещё отправить в Telegram
  bool needsSync;

  EntryData({
    this.id,
    this.localId,
    required this.date,
    required this.time,
    DateTime? createdAt,
    this.rating = '',
    this.ratingReason = '',
    this.bedTime = '',
    this.wakeTime = '',
    this.sleepDuration = '',
    this.steps = '',
    this.activity = '',
    this.energy = '',
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
    this.needsSync = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'date': date,
        'time': time,
        'createdAt': createdAt.toIso8601String(),
        'rating': rating,
        'ratingReason': ratingReason,
        'bedTime': bedTime,
        'wakeTime': wakeTime,
        'sleepDuration': sleepDuration,
        'steps': steps,
        'activity': activity,
        'energy': energy,
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
        'needsSync': needsSync ? 1 : 0,
      };

  factory EntryData.fromMap(Map<String, dynamic> m, {String? id}) {
    final created = m['createdAt'] as String?;
    return EntryData(
      id: id,
      localId: m['id'] as int?,
      date: m['date'] ?? '',
      time: m['time'] ?? '',
      createdAt: created != null
          ? DateTime.parse(created).toLocal()
          : DateTime.now(),
      rating: m['rating'] ?? '',
      ratingReason: m['ratingReason'] ?? '',
      bedTime: m['bedTime'] ?? '',
      wakeTime: m['wakeTime'] ?? '',
      sleepDuration: m['sleepDuration'] ?? '',
      steps: m['steps'] ?? '',
      activity: m['activity'] ?? '',
      energy: m['energy'] ?? '',
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
    );
  }

  String get createdAtFormatted =>
      '${createdAt.day.toString().padLeft(2, '0')}-'
      '${createdAt.month.toString().padLeft(2, '0')}-'
      '${createdAt.year} '
      '${createdAt.hour.toString().padLeft(2, '0')}:' 
      '${createdAt.minute.toString().padLeft(2, '0')}';
}
