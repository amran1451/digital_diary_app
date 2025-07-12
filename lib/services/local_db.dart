// lib/services/local_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry_data.dart';

class LocalDb {
  static Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'diary.db'),
      version: 9,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            time TEXT,
            place TEXT,
            createdAt TEXT,
            rating TEXT,
            ratingReason TEXT,
            bedTime TEXT,
            wakeTime TEXT,
            sleepDuration TEXT,
            steps TEXT,
            activity TEXT,
            energy TEXT,
            wellBeing TEXT,
            mood TEXT,
            mainEmotions TEXT,
            influence TEXT,
            important TEXT,
            tasks TEXT,
            notDone TEXT,
            thought TEXT,
            development TEXT,
            qualities TEXT,
            growthImprove TEXT,
            pleasant TEXT,
            tomorrowImprove TEXT,
            stepGoal TEXT,
            flow TEXT,
            notificationsLog TEXT,
            highlights TEXT,
            raw TEXT,
            needsSync INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE places(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            place TEXT UNIQUE COLLATE NOCASE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN raw TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE entries ADD COLUMN highlights TEXT');
        }
        if (oldVersion < 4) {
          final cols = await db.rawQuery('PRAGMA table_info(entries)');
          final exists = cols.any((c) => c['name'] == 'highlights');
          if (!exists) {
            await db.execute('ALTER TABLE entries ADD COLUMN highlights TEXT');
          }
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE entries ADD COLUMN notificationsLog TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE entries ADD COLUMN wellBeing TEXT');
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE entries ADD COLUMN place TEXT');
        }
        if (oldVersion < 8) {
          await db.execute('UPDATE entries SET wellBeing = NULL WHERE wellBeing = ? OR wellBeing = ?', ['OK', 'Всё хорошо']);
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS places(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              place TEXT UNIQUE COLLATE NOCASE
            )
          ''');
          await db.execute('''
            INSERT OR IGNORE INTO places(place)
            SELECT DISTINCT place FROM entries WHERE TRIM(place) <> ''
          ''');
        }
      },
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS places(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            place TEXT UNIQUE COLLATE NOCASE
          )
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO places(place)
          SELECT DISTINCT place FROM entries WHERE TRIM(place) <> ''
        ''');
      },
    );
  }

  /// Exposes the database instance for other services.
  static Future<Database> open() => _openDb();

  /// Вставка или обновление
  static Future<int> saveOrUpdate(EntryData e) async {
    final db = await _openDb();
    final map = e.toMap();
    if (e.localId != null) {
      await db.update('entries', map, where: 'id = ?', whereArgs: [e.localId]);
      return e.localId!;
    }
    final id = await db.insert('entries', map);
    e.localId = id;
    return id;
  }

  /// Отметить запись как синхронизированную
  static Future<void> markSynced(int localId) async {
    final db = await _openDb();
    await db.update(
      'entries',
      {'needsSync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Отметить все записи как синхронизированные
  static Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('entries', {'needsSync': 0});
  }

  /// Снять отметку "отправлено" со всех записей
  static Future<void> markAllUnsent() async {
    final db = await _openDb();
    await db.update('entries', {'needsSync': 1});
  }

  /// Полная выборка
  static Future<List<EntryData>> fetchAll() => fetchFiltered();

  /// Фильтрация по дате, рейтингу и поиску
  static Future<List<EntryData>> fetchFiltered({
    DateTime? from,
    DateTime? to,
    int? minRating,
    String? search,
  }) async {
    final db = await _openDb();
    final where = <String>[];
    final args = <dynamic>[];

    if (minRating != null) {
      where.add('CAST(rating AS INTEGER) = ?');
      args.add(minRating);
    }
    if (search != null && search.trim().isNotEmpty) {
      final pat = '%${search.trim()}%';
      const cols = [
        'date','time','place','rating','ratingReason','bedTime','wakeTime','sleepDuration',
        'steps','activity','energy','mood','mainEmotions','influence','important',
        'wellBeing','tasks','notDone','thought','development','qualities','growthImprove',
        'pleasant','tomorrowImprove','stepGoal','flow'
      ];
      final clause = cols.map((c) => '$c LIKE ?').join(' OR ');
      where.add('($clause)');
      args.addAll(List.filled(cols.length, pat));
    }

    final rows = await db.query(
      'entries',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'createdAt DESC',
    );

    List<EntryData> result =
    rows.map((m) => EntryData.fromMap(m, id: null)).toList();

    if (from != null || to != null) {
      result = result.where((e) {
        final parts = e.date.split('-');
        if (parts.length != 3) return false;
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day == null || month == null || year == null) return false;
        final dt = DateTime(year, month, day);
        if (from != null && dt.isBefore(from)) return false;
        if (to != null && dt.isAfter(to)) return false;
        return true;
      }).toList();
    }

    return result;
  }

  static Future<void> delete(int localId) async {
    final db = await _openDb();
    await db.delete('entries', where: 'id = ?', whereArgs: [localId]);
  }

  static Future<void> clearAll() async {
    final db = await _openDb();
    await db.delete('entries');
  }

  static Future<void> clearHighlights() async {
    final db = await _openDb();
    await db.update('entries', {'highlights': ''});
  }

  static Future<EntryData?> getByDate(String date) async {
    final db = await _openDb();
    final rows = await db.query(
      'entries',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EntryData.fromMap(rows.first);
  }
}
