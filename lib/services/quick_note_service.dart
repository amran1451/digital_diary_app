import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuickNoteService {
  static const _key = 'quick_notes';

  static Future<Map<String, Map<String, String>>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((date, notes) => MapEntry(
        date, Map<String, String>.from(notes as Map<dynamic, dynamic>)));
  }

  static Future<void> _saveAll(Map<String, Map<String, String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<String?> getNote(String date, String field) async {
    final all = await _loadAll();
    return all[date]?[field];
  }

  static Future<Map<String, String>> getNotesForDate(String date) async {
    final all = await _loadAll();
    return Map<String, String>.from(all[date] ?? {});
  }

  static Future<void> saveNote(
      String date, String field, String text) async {
    final all = await _loadAll();
    final notes = all.putIfAbsent(date, () => {});
    if (text.isEmpty) {
      notes.remove(field);
    } else {
      notes[field] = text;
    }
    if (notes.isEmpty) {
      all.remove(date);
    } else {
      all[date] = notes;
    }
    await _saveAll(all);
  }

  static Future<void> deleteNote(String date, String field) async {
    await saveNote(date, field, '');
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