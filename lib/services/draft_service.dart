import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry_data.dart';

class DraftService {
  static const _key = 'draft_entry';

  /// Текущий черновик в памяти
  static EntryData? currentDraft;

  /// Загружает черновик из SharedPreferences (или null)
  static Future<EntryData?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    currentDraft = EntryData.fromMap(map);
    return currentDraft;
  }

  /// Сохраняет currentDraft в SharedPreferences
  static Future<void> saveDraft() async {
    if (currentDraft == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(currentDraft!.toMap()));
  }

  /// Удаляет черновик
  static Future<void> clearDraft() async {
    currentDraft = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
