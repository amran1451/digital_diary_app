import 'package:csv/csv.dart';
import '../models/entry_data.dart';
import '../models/notification_log_item.dart';
import '../utils/parse_utils.dart';
import '../utils/wellbeing_utils.dart';
import 'dart:convert';

class CsvService {
  static const headers = [
    'date',
    'time',
    'place',
    'createdAt',
    'rating',
    'ratingReason',
    'bedTime',
    'wakeTime',
    'sleepDuration',
    'steps',
    'activity',
    'energy',
    'wellBeing',
    'mood',
    'mainEmotions',
    'influence',
    'important',
    'tasks',
    'notDone',
    'thought',
    'development',
    'qualities',
    'growthImprove',
    'pleasant',
    'tomorrowImprove',
    'stepGoal',
    'flow',
    'notificationsLog',
    'highlights',
    'raw'
  ];

  static String generateCsv(List<EntryData> entries) {
    final rows = <List<dynamic>>[headers];
    for (final e in entries) {
      rows.add([
        e.date,
        e.time,
        e.place,
        e.createdAt.toIso8601String(),
        e.rating,
        e.ratingReason,
        e.bedTime,
        e.wakeTime,
        e.sleepDuration,
        e.steps,
        e.activity,
        e.energy,
        WellBeingUtils.format(e.wellBeing),
        e.mood,
        e.mainEmotions,
        e.influence,
        e.important,
        e.tasks,
        e.notDone,
        e.thought,
        e.development,
        e.qualities,
        e.growthImprove,
        e.pleasant,
        e.tomorrowImprove,
        e.stepGoal,
        e.flow,
        jsonEncode(e.notificationsLog.map((n) => n.toMap()).toList()),
        e.highlights,
        e.raw,
      ]);
    }
    const converter = ListToCsvConverter();
    return converter.convert(rows);
  }

  static List<EntryData> parseCsv(String csvStr) {
    var data = csvStr.trimLeft();
    if (data.startsWith('\uFEFF')) {
      data = data.substring(1);
    }
    // Auto-detect delimiter (comma or semicolon)
    CsvToListConverter conv;
    if (data.contains(';') && !data.contains(',')) {
      conv = const CsvToListConverter(fieldDelimiter: ';');
    } else {
      conv = const CsvToListConverter();
    }

    final rows = conv.convert(data);
    if (rows.isEmpty) return [];
    final header = rows.first.map((e) => e.toString()).toList();
    final entries = <EntryData>[];
    for (final r in rows.skip(1)) {
      final m = Map<String, dynamic>.fromIterables(header, r);
      entries.add(EntryData(
        date: m['date']?.toString() ?? '',
        time: m['time']?.toString() ?? '',
        place: m['place']?.toString() ?? '',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '')
            ?.toLocal() ??
            DateTime.now(),
        rating: m['rating']?.toString() ?? '',
        ratingReason: m['ratingReason']?.toString() ?? '',
        bedTime: m['bedTime']?.toString() ?? '',
        wakeTime: m['wakeTime']?.toString() ?? '',
        sleepDuration: m['sleepDuration']?.toString() ?? '',
        steps: m['steps']?.toString() ?? '',
        activity: m['activity']?.toString() ?? '',
        energy: ParseUtils
            .parseDouble(m['energy']?.toString() ?? '')
            .toInt()
            .toString(),
        wellBeing: m['wellBeing'] == null
            ? null
            : WellBeingUtils.normalize(m['wellBeing'].toString()),
        mood: m['mood']?.toString() ?? '',
        mainEmotions: m['mainEmotions']?.toString() ?? '',
        influence: m['influence']?.toString() ?? '',
        important: m['important']?.toString() ?? '',
        tasks: m['tasks']?.toString() ?? '',
        notDone: m['notDone']?.toString() ?? '',
        thought: m['thought']?.toString() ?? '',
        development: m['development']?.toString() ?? '',
        qualities: m['qualities']?.toString() ?? '',
        growthImprove: m['growthImprove']?.toString() ?? '',
        pleasant: m['pleasant']?.toString() ?? '',
        tomorrowImprove: m['tomorrowImprove']?.toString() ?? '',
        stepGoal: m['stepGoal']?.toString() ?? '',
        flow: m['flow']?.toString() ?? '',
        notificationsLog: (m['notificationsLog'] != null && m['notificationsLog'].toString().isNotEmpty)
            ? List<Map<String, dynamic>>.from(jsonDecode(m['notificationsLog']))
            .map((n) => NotificationLogItem.fromMap(n))
            .toList()
            : [],
        highlights: m['highlights']?.toString() ?? '',
        raw: m['raw']?.toString() ?? '',
      ));
    }
    return entries;
  }
}