import 'package:sqflite/sqflite.dart';
import 'local_db.dart';

class PlaceService {
  static List<String> _cache = [];

  static Future<Database> _openDb() async {
    // Ensure the database schema is created by delegating to LocalDb.
    return LocalDb.open();
  }

  static Future<void> init() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
        'SELECT DISTINCT place FROM places ORDER BY place');
    _cache = rows.map((e) => e['place'] as String).toList();
  }

  static Future<List<String>> getSuggestions(String input) async {
    if (_cache.isEmpty) await init();
    if (input.isEmpty) return _cache;
    final lower = input.toLowerCase();
    return _cache
        .where((p) => p.toLowerCase().contains(lower))
        .toList();
  }

  static Future<void> savePlace(String place) async {
    final value = place.trim();
    if (value.isEmpty) return;
    final db = await _openDb();
    await db.insert('places', {'place': value},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    if (!_cache.contains(value)) _cache.add(value);
  }
}