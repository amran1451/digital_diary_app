// lib/screens/import_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/entry_data.dart';
import '../../services/csv_service.dart';
import 'import_preview_screen.dart';

class ImportScreen extends StatefulWidget {
  static const routeName = '/import';
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isParsing = false;
  String? _errorMessage;
  bool _useBotFormat = false;
  bool _useCsv = false;

  Future<void> _loadFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final f = File(path);
    final content = await f.readAsString();
    setState(() {
      _textController.text = content;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _previewEntries() async {
    final raw = _textController.text;
    if (raw.trim().isEmpty) return;
    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });
    try {
      final List<EntryData> entries = _useCsv
          ? CsvService.parseCsv(raw)
          : _useBotFormat
          ? _parseBotEntries(raw)
          : _parseEntries(raw);
      Navigator.pushNamed(
        context,
        ImportPreviewScreen.routeName,
        arguments: entries,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при разборе: $e';
      });
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  /// Старый парсер (из приложения)
  List<EntryData> _parseEntries(String input) {
    final lines = input.split(RegExp(r'\r?\n'));
    final result = <EntryData>[];
    Map<String, dynamic>? current;
    StringBuffer? buffer;
    bool inEmotions = false,
         inInfluence = false,
         inImportant = false,
         inTasks = false,
         inNotDone = false,
         inThought = false,
         inDevelopment = false,
         inQualities = false,
         inGrowthImprove = false,
         inTomorrowImprove = false,
         inStepGoal = false,
         inPleasant = false,
         inFlow = false;

    DateTime advanceTime(DateTime date, String timeStr) {
      final parts = timeStr.split(RegExp(r'[: ]'));
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final base = h < 8 ? date.add(const Duration(days: 1)) : date;
      return DateTime(base.year, base.month, base.day, h, m);
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.toLowerCase().startsWith('дневник,')) continue;
      if (line.startsWith('🔹')) {
        inEmotions = inInfluence = inImportant = inTasks =
        inNotDone = inThought = inDevelopment = inQualities =
        inGrowthImprove = inTomorrowImprove = inStepGoal =
        inPleasant = inFlow = false;
        continue;
      }
      if (line.startsWith('📖 ДНЕВНИК |')) {
        if (current != null && buffer != null) {
          result.add(_createEntry(current, buffer.toString()));
        }
        buffer = StringBuffer();
        buffer.writeln(rawLine);
        final parts = line.split('|');
        final dateStr = parts.length > 1 ? parts[1].trim() : '';
        DateTime parsedDate;
        try {
          final dp = dateStr.split('-');
          parsedDate = DateTime(
            int.parse(dp[2]), int.parse(dp[1]), int.parse(dp[0])
          );
        } catch (_) {
          parsedDate = DateTime.now();
        }
        current = {
          'date': dateStr,
          'time': '',
          'createdAt': parsedDate,
          'rating': '', 'ratingReason': '',
          'bedTime': '', 'wakeTime': '', 'sleepDuration': '',
          'steps': '', 'activity': '', 'energy': '',
          'mood': '', 'mainEmotions': '', 'influence': '',
          'important': '', 'tasks': '', 'notDone': '',
          'thought': '', 'development': '', 'qualities': '',
          'growthImprove': '', 'pleasant': '', 'tomorrowImprove': '',
          'stepGoal': '', 'flow': ''
        };
        continue;
      }
      if (current == null) continue;
      buffer?.writeln(rawLine);

      if (line.startsWith('⏳ Время записи:')) {
        final t = line.substring(line.indexOf(':') + 1).trim();
        current['time'] = t;
        current['createdAt'] = advanceTime(
          current['createdAt'] as DateTime, t
        );
        continue;
      }

      if (line.startsWith('📊')) {
        final rest = line.split(':').skip(1).join(':').trim();
        final parts = rest.split(RegExp(r'\s*[-–—]\s*'));
        current['rating'] = parts[0].trim();
        current['ratingReason'] = parts.length > 1 ? parts[1].trim() : '';
        continue;
      }

      if (line.startsWith('😴 Сон:')) {
        final data = line.substring(line.indexOf(':') + 1).trim();
        final m = RegExp(
          r'л[её]г в\s*([^,]+),\s*проснулся в\s*([^,]+),\s*спал\s*(.+)',
          caseSensitive: false
        ).firstMatch(data);
        if (m != null) {
          current['bedTime'] = m.group(1)!.trim();
          current['wakeTime'] = m.group(2)!.trim();
          current['sleepDuration'] = m.group(3)!.trim();
        } else {
          current['sleepDuration'] = data;
        }
        continue;
      }

      if (line.startsWith('🚶 Шаги:')) {
        current['steps'] = line.substring(8).trim();
        continue;
      }

      if (line.startsWith('🔥 Активность:')) {
        current['activity'] = line.substring(14).trim();
        continue;
      }

      if (line.contains('⚡') && line.contains('Энергия')) {
        final idx = line.indexOf(':');
        final data = idx >= 0 ? line.substring(idx + 1).trim() : '';
        final num = RegExp(r'(\d+)').firstMatch(data)?.group(1) ?? data;
        current['energy'] = num;
        continue;
      }

      if (line.startsWith('😊 Общее настроение:') ||
          line.startsWith('😊 Настроение:')) {
        final idx = line.indexOf(':');
        current['mood'] = idx >= 0 ? line.substring(idx + 1).trim() : '';
        continue;
      }

      if (line.startsWith('🎭 Главные эмоции дня:')) {
        final rest = line.split(':').skip(1).join(':').trim();
        current['mainEmotions'] = rest;
        inEmotions = true;
        continue;
      }
      if (inEmotions) {
        if (line.startsWith('💭')) inEmotions = false;
        else {
          current['mainEmotions'] +=
            (current['mainEmotions'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('💭 Что повлияло на настроение')) {
        final rest = line.split(RegExp(r'[:?]')).skip(1).join(':').trim();
        current['influence'] = rest;
        inInfluence = rest.isEmpty;
        continue;
      }
      if (inInfluence) {
        if (line.startsWith('🔹')) inInfluence = false;
        else {
          current['influence'] +=
            (current['influence'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('✅ Что сделал важного?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['important'] = rest;
        inImportant = true;
        continue;
      }
      if (inImportant) {
        if (line.startsWith('📌')) inImportant = false;
        else {
          current['important'] +=
            (current['important'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('📌 Какие задачи выполнил?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['tasks'] = rest;
        inTasks = true;
        continue;
      }
      if (inTasks) {
        if (line.startsWith('⏳')) inTasks = false;
        else {
          current['tasks'] +=
            (current['tasks'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('⏳ Что не успел и почему?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['notDone'] = rest;
        inNotDone = true;
        continue;
      }
      if (inNotDone) {
        if (line.startsWith('💡')) inNotDone = false;
        else {
          current['notDone'] +=
            (current['notDone'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('💡 Самая важная мысль дня:')) {
        final rest = line.split(':').skip(1).join(':').trim();
        current['thought'] = rest;
        inThought = true;
        continue;
      }
      if (inThought) {
        if (line.startsWith('📖')) inThought = false;
        else {
          current['thought'] +=
            (current['thought'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('📖 Как развивался?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['development'] = rest;
        inDevelopment = rest.isEmpty;
        continue;
      }
      if (inDevelopment) {
        if (line.startsWith('💪')) inDevelopment = false;
        else {
          current['development'] +=
            (current['development'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('💪 Какие личные качества укрепил?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['qualities'] = rest;
        inQualities = rest.isEmpty;
        continue;
      }
      if (inQualities) {
        if (line.startsWith('🎯')) inQualities = false;
        else {
          current['qualities'] +=
            (current['qualities'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('🎯 Что могу улучшить завтра?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['growthImprove'] = rest;
        inGrowthImprove = rest.isEmpty;
        continue;
      }
      if (inGrowthImprove) {
        if (line.startsWith('🌟')) inGrowthImprove = false;
        else {
          current['growthImprove'] +=
            (current['growthImprove'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('🌟 Самый приятный момент дня:')) {
        final rest = line.split(':').skip(1).join(':').trim();
        current['pleasant'] = rest;
        inPleasant = rest.isEmpty;
        continue;
      }
      if (inPleasant) {
        if (line.startsWith('🚀')) inPleasant = false;
        else {
          current['pleasant'] +=
            (current['pleasant'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('🚀 Что можно улучшить завтра?')) {
        final rest = line.split('?').skip(1).join('?').trim();
        current['tomorrowImprove'] = rest;
        inTomorrowImprove = rest.isEmpty;
        continue;
      }
      if (inTomorrowImprove) {
        if (line.startsWith('🎯')) inTomorrowImprove = false;
        else {
          current['tomorrowImprove'] +=
            (current['tomorrowImprove'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('🎯 Один шаг к цели на завтра:')) {
        final rest = line.split(':').skip(1).join(':').trim();
        current['stepGoal'] = rest;
        inStepGoal = rest.isEmpty;
        continue;
      }
      if (inStepGoal) {
        if (line.startsWith('💬')) inStepGoal = false;
        else {
          current['stepGoal'] +=
            (current['stepGoal'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }

      if (line.startsWith('💬 Поток мысли')) {
        inFlow = true;
        current['flow'] = '';
        continue;
      }
      if (inFlow) {
        if (line.startsWith('🔹')) inFlow = false;
        else {
          current['flow'] +=
            (current['flow'].isNotEmpty ? '\n' : '') + line;
          continue;
        }
      }
    }

    if (current != null && buffer != null) {
      result.add(_createEntry(current, buffer.toString()));
    }
    return result;
  }

  /// Новый парсер (из Telegram-бота)
  List<EntryData> _parseBotEntries(String input) {
    final lines = input.split(RegExp(r'\r?\n'));
    final result = <EntryData>[];
    Map<String, dynamic>? current;
    StringBuffer? buffer;
    bool inFlow = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.toLowerCase().startsWith('двеник,')) {
        continue;
      }
      // Новая запись
      if (line.startsWith('📖 ДНЕВНИК |')) {
        if (current != null && buffer != null) {
          result.add(_createEntry(current, buffer.toString()));
        }
        buffer = StringBuffer();
        buffer.writeln(rawLine);
        // вынимем всё после "|"
        final header = line.substring(line.indexOf('|') + 1).trim();
        // попробуем выцепить “за DD-MM-YYYY”
        final m = RegExp(r'за\s*(\d{2}-\d{2}-\d{4})').firstMatch(header);
        final dateStr = m != null ? m.group(1)! : header.replaceFirst('за ', '');
        DateTime parsedDate;
        try {
          final dp = dateStr.split('-');
          parsedDate = DateTime(
            int.parse(dp[2]), int.parse(dp[1]), int.parse(dp[0])
          );
        } catch (_) {
          parsedDate = DateTime.now();
        }
        current = {
          'date': dateStr,
          'time': '',
          'createdAt': parsedDate,
          'rating': '', 'ratingReason': '',
          'bedTime': '', 'wakeTime': '', 'sleepDuration': '',
          'steps': '', 'activity': '', 'energy': '',
          'mood': '', 'mainEmotions': '', 'influence': '',
          'important': '', 'tasks': '', 'notDone': '',
          'thought': '', 'development': '', 'qualities': '',
          'growthImprove': '', 'pleasant': '', 'tomorrowImprove': '',
          'stepGoal': '', 'flow': ''
        };
        inFlow = false;
        continue;
      }
      if (current == null) continue;

      if (line.startsWith('⏰ Создано:')) {
        final rest = line.substring(line.indexOf(':') + 1).trim();
        try {
          final dt = DateFormat('dd-MM-yyyy HH:mm').parse(rest);
          current['createdAt'] = dt;
          // не трогаем current['date'], оно уже взято из «за DD-MM-YYYY»
          current['time'] = DateFormat('HH:mm').format(dt);
        } catch (_) {}
        continue;
      }

      if (line.startsWith('📊 Оценка:')) {
        final rest = line.substring(line.indexOf(':') + 1).trim();
        final parts = rest.split(RegExp(r'\s*[-–—]\s*'));
        current['rating'] = parts[0].trim();
        current['ratingReason'] = parts.length > 1 ? parts[1].trim() : '';
        continue;
      }

      if (line.startsWith('😴 Сон:')) {
        final rest = line.substring(line.indexOf(':') + 1).trim();
        final m = RegExp(r'([^→]+)→([^(\n]+)\(([^)]+)\)').firstMatch(rest);
        if (m != null) {
          current['bedTime'] = m.group(1)!.trim();
          current['wakeTime'] = m.group(2)!.trim();
          current['sleepDuration'] = m.group(3)!.trim();
        }
        continue;
      }

      if (line.startsWith('🚶 Шаги:')) {
        var r = line.substring(line.indexOf(':') + 1).trim();
        if (r.startsWith(':')) r = r.substring(1).trim();
        current['steps'] = r;
        continue;
      }

      if (line.startsWith('🔥 Активность:')) {
        current['activity'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('⚡️ Энергия:')) {
        current['energy'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('😊 Настроение:')) {
        current['mood'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('🎭 Эмоции:')) {
        current['mainEmotions'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('💭 Влияние:')) {
        current['influence'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('✅ Важного:')) {
        current['important'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('📌 Задачи:')) {
        current['tasks'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('⏳ Не успел:')) {
        current['notDone'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('💡 Мысль:')) {
        current['thought'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('📖 Развитие:')) {
        current['development'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('💪 Качества:')) {
        current['qualities'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('🎯 Улучшить:')) {
        current['growthImprove'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('🌟 Приятное:')) {
        current['pleasant'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('🚀 Улучшить завтра:')) {
        current['tomorrowImprove'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('🎯 Шаг к цели:')) {
        current['stepGoal'] = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (line.startsWith('💬 Поток мысли')) {
        inFlow = true;
        current['flow'] = '';
        continue;
      }
      if (inFlow) {
        current['flow'] +=
          (current['flow'].isNotEmpty ? '\n' : '') + line;
        continue;
      }
    }

    if (current != null && buffer != null) {
      result.add(_createEntry(current, buffer.toString()));
    }
    return result;
  }

  EntryData _createEntry(Map<String, dynamic> m, [String raw = '']) => EntryData(
    date: m['date'] as String,
    time: m['time'] as String,
    createdAt: m['createdAt'] as DateTime,
    rating: m['rating'] as String,
    ratingReason: m['ratingReason'] as String,
    bedTime: m['bedTime'] as String,
    wakeTime: m['wakeTime'] as String,
    sleepDuration: m['sleepDuration'] as String,
    steps: m['steps'] as String,
    activity: m['activity'] as String,
    energy: m['energy'] as String,
    mood: m['mood'] as String,
    mainEmotions: m['mainEmotions'] as String,
    influence: m['influence'] as String,
    important: m['important'] as String,
    tasks: m['tasks'] as String,
    notDone: m['notDone'] as String,
    thought: m['thought'] as String,
    development: m['development'] as String,
    qualities: m['qualities'] as String,
    growthImprove: m['growthImprove'] as String,
    pleasant: m['pleasant'] as String,
    tomorrowImprove: m['tomorrowImprove'] as String,
    stepGoal: m['stepGoal'] as String,
    flow: m['flow'] as String,
    raw: raw,
    needsSync: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт записей')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Импорт из Telegram-бота'),
              value: _useBotFormat,
              onChanged: (v) => setState(() => _useBotFormat = v),
            ),
            SwitchListTile(
              title: const Text('CSV формат'),
              value: _useCsv,
              onChanged: (v) => setState(() => _useCsv = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Вставьте сюда ваши записи…',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Загрузить из файла'),
              onPressed: _loadFromFile,
            ),
            const SizedBox(height: 12),
            if (_isParsing) const CircularProgressIndicator(),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isParsing ? null : _previewEntries,
              child: const Text('Предпросмотр'),
            ),
          ],
        ),
      ),
    );
  }
}
