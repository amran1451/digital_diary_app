import 'package:shared_preferences/shared_preferences.dart';

class PlaceHistoryService {
  static const _key = 'place_history';
  static Future<List<String>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addPlace(String place, {int max = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(place);
    list.insert(0, place);
    if (list.length > max) list.removeRange(max, list.length);
    await prefs.setStringList(_key, list);
  }
}