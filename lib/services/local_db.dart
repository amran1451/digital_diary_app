// lib/services/local_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry_data.dart';

class LocalDb {
  static Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'diary.db'),
      version: 2,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            time TEXT,
            createdAt TEXT,
            rating TEXT,
            ratingReason TEXT,
            bedTime TEXT,
            wakeTime TEXT,
            sleepDuration TEXT,
            steps TEXT,
            activity TEXT,
            energy TEXT,
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
            raw TEXT,
            needsSync INTEGER DEFAULT 1
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN raw TEXT');
        }
      },
    );
  }

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

    if (from != null) {
      where.add('createdAt >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      where.add('createdAt <= ?');
      args.add(endOfDay.toIso8601String());
    }
    if (minRating != null) {
      where.add('CAST(rating AS INTEGER) = ?');
      args.add(minRating);
    }
    if (search != null && search.trim().isNotEmpty) {
      final pat = '%${search.trim()}%';
      const cols = [
        'date','time','rating','ratingReason','bedTime','wakeTime','sleepDuration',
        'steps','activity','energy','mood','mainEmotions','influence','important',
        'tasks','notDone','thought','development','qualities','growthImprove',
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
    return rows.map((m) => EntryData.fromMap(m, id: null)).toList();
  }

  static Future<void> delete(int localId) async {
    final db = await _openDb();
    await db.delete('entries', where: 'id = ?', whereArgs: [localId]);
  }

  static Future<void> clearAll() async {
    final db = await _openDb();
    await db.delete('entries');
  }
}
