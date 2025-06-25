class NotificationLogItem {
  final String type;
  final String sentTime;
  final String answerTime;
  final String text;

  NotificationLogItem({
    required this.type,
    required this.sentTime,
    required this.answerTime,
    required this.text,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'sentTime': sentTime,
    'answerTime': answerTime,
    'text': text,
  };

  factory NotificationLogItem.fromMap(Map<String, dynamic> m) {
    return NotificationLogItem(
      type: m['type'] ?? '',
      sentTime: m['sentTime'] ?? m['time'] ?? '',
      answerTime: m['answerTime'] ?? '',
      text: m['text'] ?? '',
    );
  }
}