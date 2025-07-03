import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickNote {
  final String time;
  final String text;

  QuickNote({required this.time, required this.text});

  Map<String, String> toMap() => {'time': time, 'text': text};

  factory QuickNote.fromMap(Map<dynamic, dynamic> m) =>
      QuickNote(time: m['time'] ?? '', text: m['text'] ?? '');
}

class QuickNoteService {
  static const _key = 'quick_notes';

  static Future<Map<String, Map<String, List<QuickNote>>>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((date, notes) {
      final fields = Map<String, dynamic>.from(notes as Map);
      return MapEntry(
        date,
        fields.map((field, list) {
          final l = List<Map<String, dynamic>>.from(list as List);
          return MapEntry(field, l.map(QuickNote.fromMap).toList());
        }),
      );
    });
  }

  static Future<void> _saveAll(
      Map<String, Map<String, List<QuickNote>>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = data.map((date, fields) => MapEntry(
        date,
        fields.map((f, list) =>
            MapEntry(f, list.map((n) => n.toMap()).toList()))));
    await prefs.setString(_key, jsonEncode(jsonData));
  }

  static Future<Map<String, List<QuickNote>>> getNotesForDate(
      String date) async {
    final all = await _loadAll();
    return all[date] ?? {};
  }

  static Future<QuickNote> addNote(
      String date, String field, String text) async {
    final all = await _loadAll();
    final fields = all.putIfAbsent(date, () => {});
    final list = fields.putIfAbsent(field, () => []);
    final note = QuickNote(
      time: DateFormat('HH:mm').format(DateTime.now()),
      text: text,
    );
    list.add(note);
    await _saveAll(all);
    return note;
  }

  static Future<void> deleteNote(
      String date, String field, int index) async {
    final all = await _loadAll();
    final list = all[date]?[field];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) {
      all[date]!.remove(field);
      if (all[date]!.isEmpty) {
        all.remove(date);
      }
    }
    await _saveAll(all);
  }

  static Future<void> clearForDate(String date) async {
    final all = await _loadAll();
    all.remove(date);
    await _saveAll(all);
  }

  static Future<bool> hasNotes(String date) async {
    final all = await _loadAll();
    return all[date]?.isNotEmpty ?? false;
  }
}