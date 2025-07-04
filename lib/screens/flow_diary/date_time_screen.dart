import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/local_db.dart';
import '../../services/place_history_service.dart';
import '../../services/quick_note_service.dart';
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
  EntryData? entry;
  late TextEditingController reasonCtrl;
  late TextEditingController placeCtrl;
  int _rating = 5;
  late String _ratingDesc;
  List<String> _placeHistory = [];

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
    placeCtrl = TextEditingController();
    _ratingDesc = _ratingLabels[_rating]!;

    // Откладываем вызов _initEntry на первый кадр, чтобы контекст был готов.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initEntry();
    });
  }

  Future<void> _initEntry() async {
    debugPrint('== Startup: _initEntry start');
    _placeHistory = await PlaceHistoryService.loadHistory();
    debugPrint('== Startup: place history: $_placeHistory');

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is EntryData) {
      entry = arg;
      _rating = int.tryParse(entry!.rating) ?? 5;
      _ratingDesc = _ratingLabels[_rating]!;
      reasonCtrl.text = entry!.ratingReason;
      placeCtrl.text = entry!.place;
      DraftService.currentDraft = entry!;
      await DraftService.saveDraft();
      setState(() {});
      return;
    }
    final draft = await DraftService.loadDraft();
    debugPrint('== Startup: loaded draft entry: ${draft?.toMap()}');
    if (draft != null) {
      debugPrint('  date: ${draft.date}');
      debugPrint('  time: ${draft.time}');
      debugPrint('  rating: ${draft.rating}');
      final notes = await QuickNoteService.getNotesForDate(draft.date);
      debugPrint('  draftNotes: $notes');
      debugPrint('  notificationsLog: ${draft.notificationsLog}');
    }
    if (draft != null) {
      // Проверяем, заполнил ли пользователь что-то кроме даты/времени
      const defaultRating = '5';
      const defaultEnergy = '5';
      final ratingTouched = draft.rating.trim().isNotEmpty &&
          draft.rating != defaultRating;
      final energyTouched = draft.energy.trim().isNotEmpty &&
          draft.energy != defaultEnergy;
      final wellBeingTouched = (draft.wellBeing?.trim().isNotEmpty ?? false) &&
          draft.wellBeing != 'OK';
      final fields = [
        draft.bedTime,
        draft.wakeTime,
        draft.sleepDuration,
        draft.steps,
        draft.activity,
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
      final hasEntryData = ratingTouched ||
          energyTouched ||
          wellBeingTouched ||
          fields.any((f) => f.trim().isNotEmpty);
      final notesExist = await QuickNoteService.hasNotes(draft.date);
      final hasDraftLog = draft.notificationsLog.isNotEmpty;
      debugPrint(
          '== Startup: hasEntryData=$hasEntryData, notesExist=$notesExist, hasDraftLog=$hasDraftLog');

      if (!hasDraftLog && !notesExist && hasEntryData) {
        debugPrint('== Startup: about to showRestoreDialog');
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
      } else if (notesExist || hasDraftLog) {
        // Были только черновые заметки — продолжаем без диалога
        entry = draft;
      } else {
        // Если ни одной дополнительной метрики нет — сразу новая запись
        await DraftService.clearDraft();
        entry = await _createNewEntry();
      }
    } else {
      // Черновиков нет вообще — новая запись
      entry = await _createNewEntry();
    }
    debugPrint('== Startup state entry: ${entry?.toMap()}');

    // Подготовка UI
    _rating = int.tryParse(entry!.rating) ?? 5;
    _ratingDesc = _ratingLabels[_rating]!;
    reasonCtrl.text = entry!.ratingReason;
    placeCtrl.text = entry!.place;

    DraftService.currentDraft = entry!;
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
      place: '',
      createdAt: createdAt,
    );
    e.rating = '$_rating'; // дефолтная оценка
    debugPrint('== Startup: _createNewEntry -> ${e.toMap()}');
    return e;
  } 

  @override
  void dispose() {
    reasonCtrl.dispose();
    placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final parts = entry!.date.split('-');
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
      entry!.date =
          '${two(picked.day)}-${two(picked.month)}-${picked.year}';
      DraftService.currentDraft = entry!;
      await DraftService.saveDraft();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);

    // Пока entry не инициализирован, показываем индикатор
    if (entry == null) {
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
                    'Дата: ${entry!.date}',
                    style: const TextStyle(
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
              Text('Время: ${entry!.time}'),
            ]),
            const SizedBox(height: 8),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: placeCtrl.text),
              optionsBuilder: (text) {
                if (text.text.isEmpty) return _placeHistory;
                return _placeHistory.where((p) =>
                    p.toLowerCase().contains(text.text.toLowerCase()));
              },
              onSelected: (selection) async {
                placeCtrl.text = selection;
                entry!.place = selection;
                DraftService.currentDraft = entry!;
                await DraftService.saveDraft();
                await PlaceHistoryService.addPlace(selection);
                _placeHistory = await PlaceHistoryService.loadHistory();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                placeCtrl = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    prefixText: '📍 ',
                    hintText: 'Город или локация',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) async {
                    entry!.place = v;
                    DraftService.currentDraft = entry!;
                    await DraftService.saveDraft();
                    if (v.trim().isNotEmpty) {
                      await PlaceHistoryService.addPlace(v.trim());
                      _placeHistory = await PlaceHistoryService.loadHistory();
                    }
                  },
                );
              },
            ),
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
                entry!.rating = '$_rating';
                _ratingDesc = _ratingLabels[_rating]!;
                DraftService.currentDraft = entry!;
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
                entry!.ratingReason = v;
                DraftService.currentDraft = entry!;
                await DraftService.saveDraft();
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  DraftService.currentDraft = entry!;
                  await DraftService.saveDraft();
                  Navigator.pushNamed(
                    context,
                    StateScreen.routeName,
                    arguments: entry!,
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
