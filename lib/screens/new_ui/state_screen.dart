import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';
import '../../theme/dark_diary_theme.dart';
import 'mood_screen.dart';
import '../../widgets/diary_menu_button.dart';

class StateScreenNew extends StatefulWidget {
  static const routeName = '/state-new';
  const StateScreenNew({Key? key}) : super(key: key);

  @override
  State<StateScreenNew> createState() => _StateScreenNewState();
}

class _StateScreenNewState extends State<StateScreenNew> {
  late EntryData entry;
  late TextEditingController bedCtrl;
  late TextEditingController wakeCtrl;
  late TextEditingController durationCtrl;
  late TextEditingController stepsCtrl;
  final Map<String, TextEditingController> _activityDurationCtrls = {};
  final Set<String> _selectedActivities = <String>{};
  final List<String> _allActivities = [
    'Ходьба',
    'Секс',
    'Тренировка',
    'Бег',
    'Растяжка',
    'Домашние дела',
  ];

  int _energy = 5;
  late String _energyDesc;
  static const _energyLabels = <int, String>{
    0: 'Полный упадок. Еле жив.',
    1: 'Очень слабое состояние. Хотелось только лежать.',
    2: 'Сильно вялый, без сил.',
    3: 'Усталость, мало ресурсов.',
    4: 'Чуть ниже нормы, вялость.',
    5: 'Средне. Ни плохо, ни бодро.',
    6: 'В целом норм, но не на пике.',
    7: 'Бодрость, двигаться приятно.',
    8: 'Высокая энергия, легко двигаться.',
    9: 'Почти максимум. Хочется делать.',
    10: 'Пик формы. Энергия прет. Супер состояние.',
  };

  String get _energyEmoji {
    if (_energy <= 3) return '😖';
    if (_energy <= 7) return '😐';
    return '😄';
  }

  Color get _energyColor {
    const start = Color(0xFFFF4B4B);
    const end = Color(0xFF4CAF50);
    final t = _energy / 10.0;
    return Color.lerp(start, end, t)!;
  }

  Map<String, List<QuickNote>> _notes = {};

  bool _init = false;
  bool _allGood = true;
  late TextEditingController wellCtrl;

  void _parseExistingActivities() {
    final regex = RegExp(r'^\\\s*(.*?)\\s+(\\d+.*)\$');
    for (final part in entry.activity.split(',')) {
      final item = part.trim();
      if (item.isEmpty) continue;
      final match = regex.firstMatch(item);
      String name;
      String duration;
      if (match != null) {
        name = match.group(1)!.trim();
        duration = match.group(2)!.trim();
      } else {
        name = item;
        duration = '';
      }
      _selectedActivities.add(name);
      _activityDurationCtrls[name] = TextEditingController(text: duration);
      if (!_allActivities.contains(name)) _allActivities.add(name);
    }
  }

  Future<void> _updateActivityString() async {
    final parts = <String>[];
    for (final act in _selectedActivities) {
      final dur = _activityDurationCtrls[act]?.text.trim() ?? '';
      if (dur.isNotEmpty) {
        parts.add('$act $dur');
      } else {
        parts.add(act);
      }
    }
    setState(() => entry.activity = parts.join(', '));
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  Future<void> _addCustomActivity() async {
    final nameCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая активность'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: durCtrl,
              decoration: const InputDecoration(labelText: 'Длительность'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _allActivities.add(name);
                _selectedActivities.add(name);
                _activityDurationCtrls[name] =
                    TextEditingController(text: durCtrl.text.trim());
              });
              _updateActivityString();
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final now = TimeOfDay.now();
    TimeOfDay initial;
    try {
      final parts = ctrl.text.split(':');
      initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      initial = now;
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      ctrl.text = '${two(picked.hour)}:${two(picked.minute)}';
      await _saveFields();
    }
  }

  Future<void> _pickDuration(TextEditingController ctrl) async {
    final textCtrl = TextEditingController(text: ctrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Длительность'),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(hintText: 'например, 7 ч 30 м'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, textCtrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      ctrl.text = result;
      await _saveFields();
    }
  }

  Future<void> _saveFields() async {
    entry.bedTime = bedCtrl.text;
    entry.wakeTime = wakeCtrl.text;
    entry.sleepDuration = durationCtrl.text;
    entry.steps = stepsCtrl.text;
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  Future<void> _showActivityPreset(String act) async {
    final durCtrl = TextEditingController(text: _activityDurationCtrls[act]?.text);
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Параметры $act', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: durCtrl,
              decoration: const InputDecoration(labelText: 'Длительность + интенсивность'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, durCtrl.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _activityDurationCtrls.putIfAbsent(act, () => TextEditingController());
        _activityDurationCtrls[act]!.text = result;
      });
      await _updateActivityString();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      bedCtrl = TextEditingController(text: entry.bedTime);
      wakeCtrl = TextEditingController(text: entry.wakeTime);
      durationCtrl = TextEditingController(text: entry.sleepDuration);
      stepsCtrl = TextEditingController(text: entry.steps);
      wellCtrl = TextEditingController(
        text: entry.wellBeing == 'OK' ? '' : (entry.wellBeing ?? ''),
      );
      _allGood = entry.wellBeing == null || entry.wellBeing!.isEmpty || entry.wellBeing == 'OK';
      _parseExistingActivities();

      _energy = int.tryParse(entry.energy) ?? 5;
      _energyDesc = _energyLabels[_energy]!;
      if (entry.energy.trim().isEmpty) {
        entry.energy = '$_energy';
      }
      DraftService.currentDraft = entry;
      DraftService.saveDraft();
      QuickNoteService.getNotesForDate(entry.date).then((n) {
        setState(() => _notes = n);
      });

      _init = true;
    }
  }

  @override
  void dispose() {
    bedCtrl.dispose();
    wakeCtrl.dispose();
    durationCtrl.dispose();
    stepsCtrl.dispose();
    wellCtrl.dispose();
    for (final c in _activityDurationCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addNote() async {
    final note = await DraftNoteHelper.addNote(context, entry.date, 'wellBeing');
    if (note != null) {
      setState(() => _notes.putIfAbsent('wellBeing', () => []).add(note));
    }
  }

  Future<void> _applyNote(int index) async {
    final list = _notes['wellBeing'];
    if (list == null || index >= list.length) return;
    final note = list[index];
    final text = wellCtrl.text.trim();
    wellCtrl.text = text.isEmpty ? note.text : '$text\n${note.text}';
    _allGood = false;
    await QuickNoteService.deleteNote(entry.date, 'wellBeing', index);
    setState(() => _notes['wellBeing']?.removeAt(index));
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  Future<void> _deleteNote(int index) async {
    await QuickNoteService.deleteNote(entry.date, 'wellBeing', index);
    setState(() => _notes['wellBeing']?.removeAt(index));
  }

  Widget _sleepCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('😴 Сон', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: AutoSizeText(
                                      '🛌 ${bedCtrl.text}',
                                      maxLines: 1,
                                      minFontSize: 12,
                                    ),
                  onPressed: () => _pickTime(bedCtrl),
                ),
                ActionChip(
                 label: AutoSizeText(
                                     '⏰ ${wakeCtrl.text}',
                                     maxLines: 1,
                                     minFontSize: 12,
                                   ),
                  onPressed: () => _pickTime(wakeCtrl),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
                          alignment: Alignment.center,
                          child: ActionChip(
                            label: AutoSizeText(
                                                          '⏳ ${durationCtrl.text}',
                                                          maxLines: 1,
                                                          minFontSize: 12,
                                                        ),
                            onPressed: () => _pickDuration(durationCtrl),
                          ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepsCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🚶 Шаги', style: theme.textTheme.titleMedium),
             const SizedBox(height: 8),
             Wrap(
                spacing: 8,
                children: [
                    ActionChip(
                        label: AutoSizeText(
                            '🚶 ${stepsCtrl.text.isEmpty ? '0' : stepsCtrl.text} шагов',
                            maxLines: 1,
                            minFontSize: 12,
                        ),
                        onPressed: () async {
                            final ctrl = TextEditingController(text: stepsCtrl.text);
                            final res = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                    title: const Text('Шаги'),
                                    content: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                    ),
                                    actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Отмена'),
                                        ),
                                        FilledButton(
                                            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                                            child: const Text('OK'),
                                        ),
                                    ],
                                ),
                            );
                            if (res != null) {
                                stepsCtrl.text = res;
                                await _saveFields();
                            }
                        },
                    ),
                ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('🔥 Активность', style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Добавить свою активность',
                  onPressed: _addCustomActivity,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final act in _allActivities)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: () => _showActivityPreset(act),
              child: FilterChip(
                label: Text(act),
                selected: _selectedActivities.contains(act),
                onSelected: (v) async {
                          setState(() {
                            if (v) {
                              _selectedActivities.add(act);
                              _activityDurationCtrls.putIfAbsent(
                                  act, () => TextEditingController());
                            } else {
                              _selectedActivities.remove(act);
                              _activityDurationCtrls.remove(act)?.dispose();
                            }
                          });
                          await _updateActivityString();
                        },
              ),
                      ),
                    ),
                ],
              ),
            ),
            if (_selectedActivities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  for (final act in _selectedActivities)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(act)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _activityDurationCtrls[act],
                              decoration: const InputDecoration(hintText: 'Длительность'),
                              onChanged: (_) => _updateActivityString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _energyCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('⚡', style: theme.textTheme.headlineSmall),
                const SizedBox(width: 8),
                Text('Энергия $_energy / 10', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onDoubleTap: () async {
                setState(() => _energy = 5);
                entry.energy = '5';
                _energyDesc = _energyLabels[_energy]!;
                await DraftService.saveDraft();
              },
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _energyColor,
                  thumbColor: _energyColor,
                  overlayColor: _energyColor.withOpacity(0.2),
                  thumbShape: _EmojiThumb(emoji: _energyEmoji),
                ),
                child: Slider(
                  value: _energy.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_energy',
                  onChanged: (v) async {
                    setState(() {
                      _energy = v.round();
                      _energyDesc = _energyLabels[_energy]!;
                    });
                    entry.energy = '$_energy';
                    DraftService.currentDraft = entry;
                    await DraftService.saveDraft();
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(_energyDesc, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _wellBeingCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('😌 Всё хорошо'),
                    value: _allGood,
                    onChanged: (v) async {
                      setState(() => _allGood = v);
                      entry.wellBeing = v ? 'OK' : wellCtrl.text;
                      DraftService.currentDraft = entry;
                      await DraftService.saveDraft();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  onPressed: _addNote,
                ),
              ],
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['wellBeing'] ?? [],
              onApply: _applyNote,
              onDelete: _deleteNote,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _allGood
                  ? const SizedBox.shrink()
                  : TextField(
                key: const ValueKey('well'),
                controller: wellCtrl,
                minLines: 2,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Опишите, что беспокоит',
                ),
                onChanged: (v) async {
                  entry.wellBeing = v;
                  DraftService.currentDraft = entry;
                  await DraftService.saveDraft();
                },
              ),
            ),
          ],
        ),
      ),
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
          title: const Text('Состояние'),
          actions: const [DiaryMenuButton()],
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(child: Text('2/6', style: theme.textTheme.labelMedium)),
                const SizedBox(height: 8),
                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: _sleepCard()),
                                      const SizedBox(width: 8),
                                      Expanded(child: _stepsCard()),
                                    ],
                                  ),
                                ),
                const SizedBox(height: 8),
                _activityCard(),
                const SizedBox(height: 8),
                _energyCard(),
                const SizedBox(height: 8),
                _wellBeingCard(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: kElevationToShadow[2],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Назад'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    await _updateActivityString();
                    DraftService.currentDraft = entry;
                    await DraftService.saveDraft();
                    Navigator.pushNamed(
                      context,
                      MoodScreenNew.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('Далее: Настроение'),
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
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}