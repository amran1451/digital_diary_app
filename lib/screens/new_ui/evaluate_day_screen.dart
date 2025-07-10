// Migrated from date_time_screen.dart: contains full logic for starting a diary
// entry with draft handling, location suggestions and theme switching.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/local_db.dart';
import '../../services/place_history_service.dart';
import '../../services/quick_note_service.dart';
import '../../theme/dark_diary_theme.dart';
import '../../main.dart';
import 'state_screen.dart';
import '../history_diary/entries_screen.dart';
import '../../widgets/diary_menu_button.dart';

class EvaluateDayScreen extends StatefulWidget {
  static const routeName = '/evaluate-day';
  const EvaluateDayScreen({Key? key}) : super(key: key);

  @override
  State<EvaluateDayScreen> createState() => _EvaluateDayScreenState();
}

class _EvaluateDayScreenState extends State<EvaluateDayScreen> {
  EntryData? entry;
  late TextEditingController _reasonCtrl;
  late TextEditingController _placeCtrl;
  List<String> _history = [];
  int _rating = 5;
  late String _ratingDesc;

  static const _ratingLabels = <int, String>{
    0: 'Худший день.',
    1: 'Очень тяжёлый день.',
    2: 'Плохой день.',
    3: 'Ниже среднего.',
    4: 'Так себе.',
    5: 'Нейтрально.',
    6: 'Немного лучше обычного.',
    7: 'Хороший день.',
    8: 'Очень хороший.',
    9: 'Отличный.',
    10: 'Идеальный.',
  };

  Future<void> _initEntry() async {
    _history = await PlaceHistoryService.loadHistory();

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is EntryData) {
      entry = arg;
    } else {
      final draft = await DraftService.loadDraft();
      if (draft != null) {
        const defaultRating = '5';
        const defaultEnergy = '5';
        final ratingTouched =
            draft.rating.trim().isNotEmpty && draft.rating != defaultRating;
        final energyTouched =
            draft.energy.trim().isNotEmpty && draft.energy != defaultEnergy;
        final wellBeingTouched =
            (draft.wellBeing?.trim().isNotEmpty ?? false) &&
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

        if (!hasDraftLog && !notesExist && hasEntryData) {
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
          entry = draft;
        } else {
          await DraftService.clearDraft();
          entry = await _createNewEntry();
        }
      } else {
        entry = await _createNewEntry();
      }
    }

    _rating = int.tryParse(entry!.rating) ?? 5;
    _ratingDesc = _ratingLabels[_rating]!;
    _reasonCtrl.text = entry!.ratingReason;
    _placeCtrl.text = entry!.place;

    DraftService.currentDraft = entry!;
    await DraftService.saveDraft();

    if (_placeCtrl.text.isEmpty) {
      await _autoFillLocation();
      if (_placeCtrl.text.isNotEmpty) {
        entry!.place = _placeCtrl.text;
        DraftService.currentDraft = entry!;
        await DraftService.saveDraft();
      }
    }

    if (_history.length > 3) _history = _history.take(3).toList();

    setState(() {});
  }

  Future<EntryData> _createNewEntry() async {
    final all = await LocalDb.fetchAll();
    DateTime baseDate;
    if (all.isNotEmpty) {
      final fmt = DateFormat('dd-MM-yyyy');
      final dates = all.map((e) => fmt.parse(e.date)).toList()..sort();
      baseDate = dates.last.add(const Duration(days: 1));
    } else {
      baseDate = DateTime.now();
    }
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final timeStr = '${two(now.hour)}:${two(now.minute)}';
    final dateStr = '${two(baseDate.day)}-${two(baseDate.month)}-${baseDate.year}';
    final e = EntryData(
      date: dateStr,
      time: timeStr,
      place: '',
      createdAt: now,
    );
    e.rating = '$_rating';
    return e;
  }

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
    _placeCtrl = TextEditingController();
    _ratingDesc = _ratingLabels[_rating]!;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initEntry();
    });
  }

  Future<void> _loadHistory() async {
    _history = await PlaceHistoryService.loadHistory();
    if (_history.length > 3) _history = _history.take(3).toList();
    setState(() {});
  }

  Future<void> _autoFillLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final city = marks.first.locality ?? '';
        if (city.isNotEmpty && mounted) {
          _placeCtrl.text = city;
          if (entry != null && (entry!.place.isEmpty)) {
            entry!.place = city;
            DraftService.currentDraft = entry!;
            await DraftService.saveDraft();
          }
        }
      }
    } catch (_) {
      // ignore errors
    }
  }

  String get _emoji {
    if (_rating <= 3) return '😖';
    if (_rating <= 7) return '😐';
    return '😄';
  }

  Color get _trackColor {
    const start = Color(0xFFFF4B4B);
    const end = Color(0xFF4CAF50);
    final t = _rating / 10.0;
    return Color.lerp(start, end, t)!;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    if (entry == null) return;
    final parts = entry!.date.split('-');
    final initialDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      entry!.date = DateFormat('dd-MM-yyyy').format(pickedDate);
    }

    final timeParts = entry!.time.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      entry!.time = '${two(pickedTime.hour)}:${two(pickedTime.minute)}';
    }

    DraftService.currentDraft = entry!;
    await DraftService.saveDraft();
    setState(() {});
  }

  void _copyDateTime() {
    if (entry == null) return;
    final txt = '${entry!.date} ${entry!.time}';
    Clipboard.setData(ClipboardData(text: txt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date/time copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = DarkDiaryTheme.theme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
          title: const Text('Дневник'),
          actions: [
            IconButton(
              tooltip: MyApp.of(context).isDark
                  ? 'Светлая тема'
                  : 'Тёмная тема',
              icon: Icon(
                MyApp.of(context).isDark
                    ? Icons.sunny
                    : Icons.nightlight_round,
              ),
              onPressed: () {
                final appState = MyApp.of(context);
                appState.toggleTheme(!appState.isDark);
              },
            ),
            const DiaryMenuButton(),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text('1/6', style: theme.textTheme.labelMedium)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DarkDiaryTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (entry != null)
                        Text('📅 ${entry!.date}  ${entry!.time}'),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickDateTime,
                        child: const Text('Редактировать'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  optionsBuilder: (text) {
                    if (text.text.isEmpty) return _history;
                    return _history.where((p) =>
                        p.toLowerCase().contains(text.text.toLowerCase()));
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    _placeCtrl = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        filled: true,
                        hintText: 'Где ты сегодня был?',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      onChanged: (v) async {
                        if (entry == null) return;
                        entry!.place = v;
                        DraftService.currentDraft = entry!;
                        await DraftService.saveDraft();
                        if (v.trim().isNotEmpty) {
                          await PlaceHistoryService.addPlace(v.trim());
                          await _loadHistory();
                        }
                      },
                    );
                  },
                  onSelected: (v) async {
                    if (entry == null) return;
                    _placeCtrl.text = v;
                    entry!.place = v;
                    DraftService.currentDraft = entry!;
                    await DraftService.saveDraft();
                    await PlaceHistoryService.addPlace(v);
                    await _loadHistory();
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 3,
                  color: DarkDiaryTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Насколько хорошим был твой день?',
                            style: theme.textTheme.headlineSmall),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _trackColor,
                            thumbColor: _trackColor,
                            overlayColor: _trackColor.withOpacity(0.2),
                            thumbShape: _EmojiThumb(emoji: _emoji),
                          ),
                          child: Slider(
                            value: _rating.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                              onChanged: (v) async {
                              _rating = v.round();
                              if (entry != null) {
                                entry!.rating = '$_rating';
                                DraftService.currentDraft = entry!;
                                await DraftService.saveDraft();
                              }
                              setState(() {
                                _ratingDesc = _ratingLabels[_rating] ?? _ratingDesc;
                              });
                              },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_ratingDesc, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonCtrl,
                  minLines: 4,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Опиши причину (необязательно)',
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (v) async {
                    if (entry == null) return;
                    entry!.ratingReason = v;
                    DraftService.currentDraft = entry!;
                    await DraftService.saveDraft();
                  },
                ),
                const Spacer(),
                SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (entry == null) return;
                        DraftService.currentDraft = entry!;
                        await DraftService.saveDraft();
                        Navigator.pushNamed(
                          context,
                          StateScreenNew.routeName,
                          arguments: entry,
                        );
                      },
                      child: const Text('Далее: Состояние'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiThumb extends SliderComponentShape {
  final String emoji;
  const _EmojiThumb({required this.emoji});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(40, 40);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final canvas = context.canvas;
    final text = TextSpan(text: emoji, style: const TextStyle(fontSize: 24));
    final tp = TextPainter(
      text: text,
      textDirection: textDirection,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
}