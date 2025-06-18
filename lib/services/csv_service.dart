import 'package:csv/csv.dart';
import '../models/entry_data.dart';
import '../utils/parse_utils.dart';

class CsvService {
  static const headers = [
    'date',
    'time',
    'createdAt',
    'rating',
    'ratingReason',
    'bedTime',
    'wakeTime',
    'sleepDuration',
    'steps',
    'activity',
    'energy',
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
    'raw'
  ];

  static String generateCsv(List<EntryData> entries) {
    final rows = <List<dynamic>>[headers];
    for (final e in entries) {
      rows.add([
        e.date,
        e.time,
        e.createdAt.toIso8601String(),
        e.rating,
        e.ratingReason,
        e.bedTime,
        e.wakeTime,
        e.sleepDuration,
        e.steps,
        e.activity,
        e.energy,
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
        energy: ParseUtils.parseDouble(m['energy']?.toString() ?? '').toString(),
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
        raw: m['raw']?.toString() ?? '',
      ));
    }
    return entries;
  }
}