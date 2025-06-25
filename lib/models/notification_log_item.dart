class NotificationLogItem {
  final String type;
  final String time;
  final String text;

  NotificationLogItem({required this.type, required this.time, required this.text});

  Map<String, dynamic> toMap() => {
    'type': type,
    'time': time,
    'text': text,
  };

  factory NotificationLogItem.fromMap(Map<String, dynamic> m) {
    return NotificationLogItem(
      type: m['type'] ?? '',
      time: m['time'] ?? '',
      text: m['text'] ?? '',
    );
  }
}