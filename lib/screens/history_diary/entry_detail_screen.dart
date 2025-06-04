// lib/screens/entry_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import '../../main.dart';

class EntryDetailScreen extends StatefulWidget {
  static const routeName = '/entry_detail';
  const EntryDetailScreen({Key? key}) : super(key: key);

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late EntryData entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    entry = ModalRoute.of(context)!.settings.arguments as EntryData;
  }

  Future<void> _pickDate() async {
    // Parse existing date "dd-MM-yyyy"
    final parts = entry.date.split('-');
    DateTime initial;
    try {
      initial = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final newDate =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      setState(() {
        entry.date = newDate;
      });
      await LocalDb.saveOrUpdate(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Дата записи обновлена: $newDate')),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

    // Prepare text for copying
    final buffer = StringBuffer()
      ..writeln('📅 Дата записи: ${entry.date}')
      ..writeln('📝 Создано: ${entry.createdAtFormatted}')
      ..writeln()
      ..writeln('📊 Оценка дня: ${entry.rating} – ${entry.ratingReason}')
      ..writeln()
      ..writeln('😴 Сон:')
      ..writeln('  • Лёг в: ${entry.bedTime}')
      ..writeln('  • Проснулся в: ${entry.wakeTime}')
      ..writeln('  • Общее: ${entry.sleepDuration}')
      ..writeln('🚶 Шаги: ${entry.steps}')
      ..writeln('🔥 Активность: ${entry.activity}')
      ..writeln('⚡️ Энергия: ${entry.energy}')
      ..writeln()
      ..writeln('😊 Настроение: ${entry.mood}')
      ..writeln('🎭 Главные эмоции: ${entry.mainEmotions}')
      ..writeln('💭 Что повлияло на настроение: ${entry.influence}')
      ..writeln()
      ..writeln('✅ Что сделал важного: ${entry.important}')
      ..writeln('📌 Какие задачи выполнил: ${entry.tasks}')
      ..writeln('⏳ Что не успел и почему: ${entry.notDone}')
      ..writeln('💡 Самая важная мысль дня: ${entry.thought}')
      ..writeln()
      ..writeln('📖 Как развивался: ${entry.development}')
      ..writeln('💪 Какие личные качества укрепил: ${entry.qualities}')
      ..writeln('🎯 Что могу улучшить завтра: ${entry.growthImprove}')
      ..writeln()
      ..writeln('🌟 Самый приятный момент дня: ${entry.pleasant}')
      ..writeln('🚀 Что можно улучшить завтра: ${entry.tomorrowImprove}')
      ..writeln('🎯 Один шаг к цели на завтра: ${entry.stepGoal}')
      ..writeln()
      ..writeln('💬 Поток мыслей:')
      ..writeln(entry.flow);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Детали записи', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(appState.isDark ? Icons.sunny : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDark),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Скопировать запись',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Запись скопирована в буфер обмена')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: 'Изменить дату записи',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickDate,
              child: Text(
                '📅 Дата записи: ${entry.date}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Text(
              '📝 Создано: ${entry.createdAtFormatted}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const Divider(),
            Text('📊 Оценка дня: ${entry.rating} – ${entry.ratingReason}'),
            const SizedBox(height: 8),
            Text('😴 Сон:'),
            Text('  • Лёг в: ${entry.bedTime}'),
            Text('  • Проснулся в: ${entry.wakeTime}'),
            Text('  • Общее: ${entry.sleepDuration}'),
            Text('🚶 Шаги: ${entry.steps}'),
            Text('🔥 Активность: ${entry.activity}'),
            Text('⚡️ Энергия: ${entry.energy}'),
            const Divider(),
            Text('😊 Настроение: ${entry.mood}'),
            Text('🎭 Главные эмоции: ${entry.mainEmotions}'),
            Text('💭 Что повлияло на настроение: ${entry.influence}'),
            const Divider(),
            Text('✅ Что сделал важного: ${entry.important}'),
            Text('📌 Какие задачи выполнил: ${entry.tasks}'),
            Text('⏳ Что не успел и почему: ${entry.notDone}'),
            Text('💡 Самая важная мысль дня: ${entry.thought}'),
            const Divider(),
            Text('📖 Как развивался: ${entry.development}'),
            Text('💪 Какие личные качества укрепил: ${entry.qualities}'),
            Text('🎯 Что могу улучшить завтра: ${entry.growthImprove}'),
            const Divider(),
            Text('🌟 Самый приятный момент дня: ${entry.pleasant}'),
            Text('🚀 Что можно улучшить завтра: ${entry.tomorrowImprove}'),
            Text('🎯 Один шаг к цели на завтра: ${entry.stepGoal}'),
            const Divider(),
            Text(
              '💬 Поток мыслей:',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            Text(entry.flow),
          ],
        ),
      ),
    );
  }
}
