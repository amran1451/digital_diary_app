// lib/screens/preview_screen.dart

import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import '../../services/telegram_service.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../main.dart';
import '../flow_diary/date_time_screen.dart';
import '../history_diary/entries_screen.dart';
import '../history_diary/entry_detail_screen.dart';

enum _DateMenu { entries, toggleTheme }

class PreviewScreen extends StatelessWidget {
  static const routeName = '/preview';
  const PreviewScreen({Key? key}) : super(key: key);

  Future<void> _send(EntryData e, BuildContext ctx) async {
    // 1) Сохранить локально
    await LocalDb.saveOrUpdate(e);

    // 2) Отправить через сервис
    final ok = await TelegramService.sendEntry(e);

    // 3) Фидбэк
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          ok
            ? 'Запись отправлена и сохранена!'
            : 'Сохранено локально — отправьте позже'
        ),
      ),
    );

    // 4) Пауза и возврат
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pushNamedAndRemoveUntil(
      ctx,
      DateTimeScreen.routeName,
      (_) => false,
    );

    // 5) Очистить черновик
    await DraftService.clearDraft();
    await QuickNoteService.clearForDate(e.date);
  }

  Future<void> _save(EntryData e, BuildContext ctx) async {
    await LocalDb.saveOrUpdate(e);
    ScaffoldMessenger.of(ctx)
        .showSnackBar(const SnackBar(content: Text('Изменения сохранены')));
    await DraftService.clearDraft();
    await QuickNoteService.clearForDate(e.date);
    Navigator.pushNamedAndRemoveUntil(
      ctx,
      EntryDetailScreen.routeName,
          (_) => false,
      arguments: e,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = ModalRoute.of(context)!.settings.arguments as EntryData;
    final appState = MyApp.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Предпросмотр', style: TextStyle(fontSize: 16)),
        actions: [
          PopupMenuButton<_DateMenu>(
            onSelected: (item) {
              switch (item) {
                case _DateMenu.entries:
                  Navigator.pushNamed(context, EntriesScreen.routeName);
                  break;
                case _DateMenu.toggleTheme:
                  appState.toggleTheme(!appState.isDark);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _DateMenu.entries,
                child: ListTile(
                  leading: Icon(Icons.list),
                  title: Text('Мои записи'),
                ),
              ),
              PopupMenuItem(
                value: _DateMenu.toggleTheme,
                child: ListTile(
                  leading: Icon(
                    appState.isDark
                      ? Icons.sunny
                      : Icons.nightlight_round
                  ),
                  title: Text(
                    appState.isDark
                      ? 'Светлая тема'
                      : 'Тёмная тема'
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    '📅 Дата: ${entry.date}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '🕗 Создано: ${entry.createdAtFormatted}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (entry.place.isNotEmpty)
                    Text('📍 Место: ${entry.place}'),
                  const Divider(),
                  ..._buildDetailLines(entry),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Назад'),
                ),
                if (entry.localId == null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Отправить'),
                    onPressed: () => _send(entry, context),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
                    onPressed: () => _save(entry, context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailLines(EntryData e) => [
        Text('📊 Оценка: ${e.rating} – ${e.ratingReason}'),
        const SizedBox(height: 8),
        Text('😴 Сон: ${e.bedTime} → ${e.wakeTime}'),
        Text('⏱ Длительность: ${e.sleepDuration}'),
        Text('🚶 Шаги: ${e.steps}'),
        Text('🔥 Активность: ${e.activity}'),
        Text('⚡️ Энергия: ${e.energy}'),
        Text('🤒 Самочувствие: ${e.wellBeing == 'OK' ? 'Всё хорошо' : (e.wellBeing ?? '')}'),
        const Divider(),
        Text('😊 Настроение: ${e.mood}'),
        Text('🎭 Эмоции: ${e.mainEmotions}'),
        Text('💭 Влияние: ${e.influence}'),
        const Divider(),
        Text('✅ Важного: ${e.important}'),
        Text('📌 Задачи: ${e.tasks}'),
        Text('⏳ Не успел: ${e.notDone}'),
        Text('💡 Мысль: ${e.thought}'),
        const Divider(),
        Text('📖 Развитие: ${e.development}'),
        Text('💪 Качества: ${e.qualities}'),
        Text('🎯 Улучшить: ${e.growthImprove}'),
        const Divider(),
        Text('🌟 Приятное: ${e.pleasant}'),
        Text('🚀 Улучшить завтра: ${e.tomorrowImprove}'),
        Text('🎯 Шаг к цели: ${e.stepGoal}'),
        const Divider(),
        Text('💬 Поток мысли:', style: TextStyle(fontSize: 16)),
        Text(e.flow),
      ];
}
