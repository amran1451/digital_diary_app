import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry_data.dart';
import 'quick_note_service.dart';

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

  /// Returns true if a draft exists and contains any non-empty data.
  static Future<bool> hasActiveDraft() async {
    final draft = await loadDraft();
    if (draft == null) return false;

    const defaultRating = '5';
    const defaultEnergy = '5';

    final ratingTouched =
        draft.rating.trim().isNotEmpty && draft.rating != defaultRating;
    final energyTouched =
        draft.energy.trim().isNotEmpty && draft.energy != defaultEnergy;
    final wellBeingTouched =
        (draft.wellBeing?.trim().isNotEmpty ?? false) &&
            draft.wellBeing != 'OK';

    final fields = [
      draft.ratingReason,
      draft.place,
      draft.bedTime,
      draft.wakeTime,
      draft.sleepDuration,
      draft.steps,
      draft.activity,
      draft.mood,
      draft.mainEmotions,
      draft.influence,
      draft.important,
      draft.tasks,
      draft.notDone,
      draft.thought,
      draft.development,
      draft.qualities,
      draft.growthImprove,
      draft.pleasant,
      draft.tomorrowImprove,
      draft.stepGoal,
      draft.flow,
      draft.raw,
      draft.highlights,
    ];

    final hasEntryData = ratingTouched ||
        energyTouched ||
        wellBeingTouched ||
        fields.any((f) => f.trim().isNotEmpty);

    return hasEntryData ||
        draft.notificationsLog.isNotEmpty ||
        await QuickNoteService.hasNotes(draft.date);
  }
}
