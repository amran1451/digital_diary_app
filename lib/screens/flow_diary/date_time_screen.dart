import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/local_db.dart';
import '../../main.dart';
import 'state_screen.dart';
import '../history_diary/entries_screen.dart';

enum _DateMenu { entries, toggleTheme }

class DateTimeScreen extends StatefulWidget {
  static const routeName = '/date';
  const DateTimeScreen({Key? key}) : super(key: key);

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  late EntryData entry;
  late TextEditingController reasonCtrl;
  int _rating = 5;
  late String _ratingDesc;

  static const _ratingLabels = <int, String>{
    0: 'Худший день. Всё было плохо, максимум стресса.',
    1: 'Очень тяжёлый день. Тоска, раздражение, упадок.',
    2: 'Плохой день. Многое не получилось, тяжело.',
    3: 'Ниже среднего. Раздражение, усталость, слабый ритм.',
    4: 'Так себе. День прошёл, но без радости.',
    5: 'Нейтрально. Без особых эмоций, просто день.',
    6: 'Немного лучше обычного. Было что-то приятное.',
    7: 'Хороший день. Получилось, настроение норм.',
    8: 'Очень хороший. Радость, прогресс, тёплое состояние.',
    9: 'Отличный. Яркие эмоции, всё шло как надо.',
    10: 'Идеальный. Максимум смысла, энергии, любви к жизни.',
  };

  @override
  void initState() {
    super.initState();
    reasonCtrl = TextEditingController();
    _ratingDesc = _ratingLabels[_rating]!;

    // Откладываем вызов _initEntry на первый кадр, чтобы контекст был готов.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initEntry();
    });
  }

  Future<void> _initEntry() async {
    final draft = await DraftService.loadDraft();
    if (draft != null) {
      // Проверяем, заполнил ли пользователь что-то кроме даты/времени
      const defaultRating = '5';
      final ratingTouched = draft.rating != defaultRating;
      final fields = [
        draft.bedTime,
        draft.wakeTime,
        draft.sleepDuration,
        draft.steps,
        draft.activity,
        draft.energy,
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
      ];
      final hasContentBeyondDateTime =
          ratingTouched || fields.any((f) => f.trim().isNotEmpty);

      if (hasContentBeyondDateTime) {
        // Предложить продолжить черновик или начать новый
        final resume = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Есть незавершённый черновик'),
            content: const Text(
                'Хотите продолжить заполнение черновика или начать новую запись?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Новая запись'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Продолжить черновик'),
              ),
            ],
          ),
        );
        if (resume == true) {
          entry = draft;
        } else {
          await DraftService.clearDraft();
          entry = await _createNewEntry();
        }
      } else {
        // Если ни одной дополнительной метрики нет — сразу новая запись
        await DraftService.clearDraft();
        entry = await _createNewEntry();
      }
    } else {
      // Черновиков нет вообще — новая запись
      entry = await _createNewEntry();
    }

    // Подготовка UI
    _rating = int.tryParse(entry.rating) ?? 5;
    _ratingDesc = _ratingLabels[_rating]!;
    reasonCtrl.text = entry.ratingReason;

    DraftService.currentDraft = entry;
    await DraftService.saveDraft();

    setState(() {});
  }

  /// Создаёт новую запись, где дата = последний день из БД +1, либо сегодня
  Future<EntryData> _createNewEntry() async {
    final all = await LocalDb.fetchAll();

    // 1) вычисляем базовую дату (после последней записи)
    DateTime baseDate;
      if (all.isNotEmpty) {
        final fmt = DateFormat('dd-MM-yyyy');
        final dates = all.map((e) => fmt.parse(e.date)).toList()..sort();
        baseDate = dates.last.add(const Duration(days: 1));
      } else {
          baseDate = DateTime.now();
        }

    // 2) собираем текущее время и createdAt
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final timeStr = '${two(now.hour)}:${two(now.minute)}';
    final createdAt = now;

    // 3) форматируем дату (используем только baseDate, без времени)
    final dateStr =
        '${two(baseDate.day)}-${two(baseDate.month)}-${baseDate.year}';

    // 4) создаём EntryData
    final e = EntryData(
      date: dateStr,
      time: timeStr,
      createdAt: createdAt,
    );
    e.rating = '$_rating'; // дефолтная оценка
    return e;
  } 

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final parts = entry.date.split('-');
    final initial = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      entry.date =
          '${two(picked.day)}-${two(picked.month)}-${picked.year}';
      DraftService.currentDraft = entry;
      await DraftService.saveDraft();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);

    // Пока entry не инициализирован, показываем индикатор
    if (DraftService.currentDraft == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('📖 Дневник',
            style: TextStyle(fontSize: 16)),
        actions: [
          PopupMenuButton<_DateMenu>(
            onSelected: (item) {
              switch (item) {
                case _DateMenu.entries:
                  Navigator.pushNamed(
                      context, EntriesScreen.routeName);
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
                  leading: Icon(appState.isDark
                      ? Icons.sunny
                      : Icons.nightlight_round),
                  title: Text(appState.isDark
                      ? 'Светлая тема'
                      : 'Тёмная тема'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Text(
                    'Дата: ${entry.date}',
                    style: const TextStyle(
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
              Text('Время: ${entry.time}'),
            ]),
            const SizedBox(height: 24),
            Text(
              '📊 Оценка дня: $_rating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _rating.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_rating',
              onChanged: (v) async {
                _rating = v.toInt();
                entry.rating = '$_rating';
                _ratingDesc = _ratingLabels[_rating]!;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            Text(_ratingDesc,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Причина',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) async {
                entry.ratingReason = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  DraftService.currentDraft = entry;
                  await DraftService.saveDraft();
                  Navigator.pushNamed(
                    context,
                    StateScreen.routeName,
                    arguments: entry,
                  );
                },
                child: const Text('→ Далее: Состояние'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
