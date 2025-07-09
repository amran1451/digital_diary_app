import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../theme/dark_diary_theme.dart';
import '../flow_diary/achievements_screen.dart';

class MoodScreenNew extends StatefulWidget {
  static const routeName = '/mood-new';
  const MoodScreenNew({Key? key}) : super(key: key);

  @override
  State<MoodScreenNew> createState() => _MoodScreenNewState();
}

class _MoodScreenNewState extends State<MoodScreenNew> {
  late EntryData entry;
  bool _inited = false;
  int _rating = 5;
  String _emoji = '😐';
  int? _expanded;
  final Set<String> _selected = <String>{};

  static const _emojiCycle = ['😩', '😐', '🤩'];
  static const _emojiOptions = ['😩', '😔', '😐', '😊', '🤩'];

  String _emojiFromRating(int rating) {
      if (rating <= 3) return '😩';
      if (rating <= 7) return '😐';
      return '🤩';
    }
  static const Map<int, String> _ratingLabels = {
    1: 'Ужасно',
    2: 'Ужасно',
    3: 'Грусть',
    4: 'Грусть',
    5: 'Нейтрально',
    6: 'Нейтрально',
    7: 'Классно',
    8: 'Классно',
    9: 'Восторг',
    10: 'Восторг',
  };

  static const Map<String, List<String>> _emotionCategories = {
    '😄 Радость': [
      'Воодушевление',
      'Восторг',
      'Интерес',
      'Радость',
      'Счастье',
      'Лёгкость',
      'Теплота',
      'Любовь',
      'Обожание',
    ],
    '😔 Грусть': [
      'Печаль',
      'Одиночество',
      'Уныние',
      'Потерянность',
      'Безысходность',
      'Ностальгия',
      'Тоска',
      'Экзистенциальная тоска',
      'Меланхолия',
    ],
    '😰 Тревога': [
      'Беспокойство',
      'Неуверенность',
      'Паника',
      'Напряжение',
      'Предвкушение негатива',
      'Тревога',
      'Растерянность',
      'Трепет',
    ],
    '😡 Злость': [
      'Раздражение',
      'Обида',
      'Зависть',
      'Агрессия',
      'Неприязнь',
      'Фрустрация',
      'Сопротивление',
    ],
    '😶 Оцепенение': [
      'Пустота',
      'Замерзание',
      'Онемение',
      'Тупик',
      'Хтонь',
    ],
    '🤍 Принятие': [
      'Спокойствие',
      'Устойчивость',
      'Принятие',
      'Доверие',
      'Резонанс',
    ],
    '💭 Сложные/смешанные': [
      'Вина',
      'Стыд',
      'Смущение',
      'Неловкость',
      'Амбивалентность',
      'Уязвимость',
      'Катарсис',
    ],
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      _rating = int.tryParse(entry.mood) ?? 5;
      _rating = _rating.clamp(1, 10);
      _emoji = _emojiFromRating(_rating);
      _selected.addAll(entry.mainEmotions
          .split(RegExp(r'[;,\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty));
      _inited = true;
    }
  }

  Future<void> _save() async {
    entry.mood = '$_rating';
    entry.mainEmotions = _selected.join(', ');
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  void _toggleEmoji() {
    final idx = _emojiCycle.indexOf(_emoji);
    setState(() => _emoji = _emojiCycle[(idx + 1) % _emojiCycle.length]);
  }

  Future<void> _chooseEmoji() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Wrap(
          spacing: 8,
          children: _emojiOptions
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, e),
                    child: Semantics(
                      label: 'emoji $e',
                      child: Text(e, style: const TextStyle(fontSize: 32)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) setState(() => _emoji = selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = DarkDiaryTheme.theme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
          title: const Text('Настроение'),
          actions: [
           IconButton(
                         icon: const Icon(Icons.info_outline),
                         onPressed: () {
                           showDialog(
                             context: context,
                             builder: (ctx) => const AlertDialog(
                               content: Text(
                                   'Не запаривайся: выбери 2-3 эмоции, больше не нужно'),
                             ),
                           );
                         },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today_outlined),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text('3/6', style: theme.textTheme.labelMedium)),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _toggleEmoji,
                    onLongPress: _chooseEmoji,
                    child: Semantics(
                      label: 'mood emoji $_emoji',
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        child: Text(_emoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: _rating.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_rating',
                    onChanged: (v) async {
                      setState(() {
                                              _rating = v.round();
                                              _emoji = _emojiFromRating(_rating);
                                            });
                      await _save();
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ratingLabels[_rating]!,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (_selected.isEmpty)
                  MaterialBanner(
                    content: const Text(
                        'Добавь хотя бы одну, чтобы увидеть аналитику'),
                    actions: const [SizedBox.shrink()],
                  ),
                const SizedBox(height: 8),
                ..._emotionCategories.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entryCat) {
                  final index = entryCat.key;
                  final cat = entryCat.value.key;
                  final emotions = entryCat.value.value;
                  final expanded = _expanded == index;
                  final selectedCount =
                      emotions.where(_selected.contains).length;
                  return Card(
                    color: const Color(0xFF211C2A),
                    elevation: 1,
                    child: ExpansionTile(
                      key: ValueKey('tile_${index}_${_expanded ?? ""}'),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.all(24),
                      collapsedShape: const RoundedRectangleBorder(),
                      shape: const RoundedRectangleBorder(),
                      initiallyExpanded: expanded,
                      trailing: RotationTransition(
                        turns: AlwaysStoppedAnimation(expanded ? 0.5 : 0),
                        child: const Icon(Icons.expand_more),
                      ),
                      onExpansionChanged: (v) =>
                          setState(() => _expanded = v ? index : null),
                      title: Text(
                        selectedCount > 0 ? '$cat ($selectedCount)' : cat,
                        style: theme.textTheme.bodyLarge!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final emo in emotions)
                              Tooltip(
                                message: emo,
                                child: FilterChip(
                                  label: Text(emo),
                                  selected: _selected.contains(emo),
                                  selectedColor: const Color(0xFF4B3B7F),
                                  checkmarkColor: const Color(0xFFE6E1E5),
                                  onSelected: (v) async {
                                    setState(() {
                                      if (v) {
                                        if (_selected.length < 3) {
                                          _selected.add(emo);
                                        }
                                      } else {
                                        _selected.remove(emo);
                                      }
                                    });
                                    await _save();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
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
                    await _save();
                    Navigator.pushNamed(
                      context,
                      AchievementsScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('Достижения'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}