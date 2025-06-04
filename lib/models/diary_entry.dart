class DiaryEntry {
  final String date;
  final String message;
  DiaryEntry({required this.date, required this.message});

  Map<String, dynamic> toMap() => {'date': date, 'message': message};
  factory DiaryEntry.fromMap(Map<String, dynamic> m) =>
      DiaryEntry(date: m['date'], message: m['message']);
}
