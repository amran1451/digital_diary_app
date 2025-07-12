import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../theme/dark_diary_theme.dart';
import 'achievements_screen_new.dart';
import '../../widgets/diary_menu_button.dart';
import '../../widgets/keyboard_safe_content.dart';

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
  final Map<String, TextEditingController> _influenceCtrls = {};
  late TextEditingController _moodCtrl;
  Map<String, List<QuickNote>> _notes = {};

  static const _emojiCycle = ['😩', '😐', '🤩'];
  static const _emojiOptions = ['😩', '😔', '😐', '😊', '🤩'];

  String _emojiFromRating(int rating) {
      if (rating <= 3) return '😩';
      if (rating <= 7) return '😐';
      return '🤩';
    }
  static const Map<int, String> _ratingLabels = {
    0: 'Кризис',
    1: 'Безнадёжность',
    2: 'Уныние',
    3: 'Тревога',
    4: 'Напряжение',
    5: 'Нейтрально',
    6: 'Спокойствие',
    7: 'Удовлетворение',
    8: 'Оптимизм',
    9: 'Воодушевление',
    10: 'Эйфория',
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

  static const Map<String, String> _emotionHints = {
    'Воодушевление': 'Ты видишь цель и веришь, что «мы сделаем это!»',
    'Восторг': 'Сверхрадость: реальность превзошла ожидания',
    'Интерес': 'Нос чует новизну, мозг кричит «покажи ещё!»',
    'Радость': 'Простое «мне хорошо прямо сейчас»',
    'Счастье': 'Долгосрочное «жизнь в плюс»',
    'Лёгкость': 'Нет груза, всё по плечу',
    'Теплота': 'Душевный контакт, уют',
    'Любовь': 'Глубокая привязанность и забота',
    'Обожание': 'Любовь на стероидах, чуть идеализированная',
    'Печаль': 'Потеря или неудовлетворённая потребность',
    'Одиночество': 'Нехватка близости',
    'Уныние': 'Временный упадок сил и смысла',
    'Потерянность': 'Неясно, куда идти дальше',
    'Безысходность': 'Мир кажется запертой коробкой',
    'Ностальгия': 'Тоска по хорошему, но ушедшему',
    'Тоска': 'Неопределённая печаль + желание «чего-то»',
    'Экзистенциальная тоска':
    'Печаль о смысле жизни и своей конечности',
    'Меланхолия': 'Длинная, мягкая грусть с оттенком искусства',
    'Беспокойство': 'Что-то может пойти не так',
    'Неуверенность': 'Недостаток веры в себя/ситуацию',
    'Паника': 'Опасность кажется тотальной, времени ноль',
    'Напряжение': 'Готовность к удару/рывку',
    'Предвкушение негатива':
    'Мысленно смотришь фильм ужасов про будущее',
    'Тревога': 'Микс напряжения + беспокойства',
    'Растерянность': 'Много инфы, мало ясности',
    'Трепет': 'Сильное ожидание (плюс или минус)',
    'Раздражение': 'Что-то мешает или повторяет ошибку',
    'Обида': 'Переживание несправедливости к себе',
    'Зависть': 'У другого есть желаемое, у меня — нет',
    'Агрессия': 'Импульс атаковать, защититься или завладеть',
    'Неприязнь': 'Стабильное «не моё», неприятие',
    'Фрустрация': 'Цель заблокирована, усилия не дают результата',
    'Сопротивление': 'Внутренний отказ принять изменения',
    'Пустота': 'Эмоции обнулились или ушли в подполье',
    'Замерзание': 'Стоп-кадр от шока/страха',
    'Онемение': 'Система перегружена и выключила сенсоры',
    'Тупик': 'Ни вперёд, ни назад',
    'Хтонь': 'Экзистенциальная пустыня + тревожное бездно',
    'Спокойствие': 'Ничего не шатает лодку',
    'Устойчивость': 'Верю, что справлюсь с бурями',
    'Принятие': 'Соглашаюсь с фактом без борьбы',
    'Доверие': 'Верю, что меня не подставят',
    'Резонанс': 'Внутреннее совпадение с внешним',
    'Вина': 'Нарушил свои/чьи-то правила',
    'Стыд': '«Я плохой/неправильный» на витрине',
    'Смущение': 'Неловкий свет прожектора на мне',
    'Неловкость': 'Соц-ситуация «как бы выйти красиво?»',
    'Амбивалентность': 'Две противоположные эмоции одновременно',
    'Уязвимость': 'Чувствительность + риск быть раненым',
    'Катарсис': 'Эмоциональная разрядка и очищение',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      final parsed = int.tryParse(entry.mood);
            if (parsed != null) {
                    _rating = parsed.clamp(0, 10);
                    _moodCtrl = TextEditingController();
                  } else {
                    _rating = 5;
                    _moodCtrl = TextEditingController(text: entry.mood);
                  }
      _emoji = _emojiFromRating(_rating);
      _selected.addAll(entry.mainEmotions
          .split(RegExp(r'[;,\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty));

      final regex =
      RegExp(r'(.*?)\s*[—-]\s*(\([^)]*\)|[^,]+)(?:,|\$)');
      for (final match in regex.allMatches(entry.influence)) {
        final emo = match.group(1)!.trim();
        var text = match.group(2)!.trim();
        if (text.startsWith('(') && text.endsWith(')')) {
          text = text.substring(1, text.length - 1).trim();
        }
        _influenceCtrls[emo] = TextEditingController(text: text);
      }
      for (final emo in _selected) {
        _influenceCtrls.putIfAbsent(emo, () => TextEditingController());
      }

      _inited = true;
      DraftService.currentDraft = entry;
      DraftService.saveDraft();
      QuickNoteService.getNotesForDate(entry.date).then((n) {
        setState(() => _notes = n);
      });
    }
  }

  Future<void> _save() async {
    final text = _moodCtrl.text.trim();
    entry.mood = text.isNotEmpty ? text : '$_rating';
    entry.mainEmotions = _selected.join(', ');
    entry.influence = _buildInfluenceString();
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  String _buildInfluenceString() {
    final parts = <String>[];
    for (final emo in _selected) {
      final text = _influenceCtrls[emo]?.text.trim() ?? '';
      if (text.isNotEmpty) parts.add('$emo — $text');
    }
    return parts.join(', ');
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

  Future<void> _editDraftNote() async {
    final existing = _notes['mood']?.isNotEmpty == true ? _notes['mood']![0] : null;
    final ctrl = TextEditingController(text: existing?.text ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              minLines: 3,
              maxLines: null,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Черновая заметка'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      if (existing != null) {
        await QuickNoteService.deleteNote(entry.date, 'mood', 0);
        _notes['mood']!.removeAt(0);
      }
      final note = await QuickNoteService.addNote(entry.date, 'mood', result.trim());
      setState(() => _notes.putIfAbsent('mood', () => []).insert(0, note));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Черновик сохранён')),
        );
      }
    }
  }

  Widget _influenceCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\uD83D\uDCAD Что повлияло',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final emo in _selected)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(emo)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _influenceCtrls[emo],
                            decoration:
                            const InputDecoration(hintText: 'Что повлияло'),
                            onChanged: (_) => _save(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmotionHint(String emo) async {
    final hint = _emotionHints[emo];
    if (hint == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emo, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(hint, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _moodCtrl.dispose();
    for (final c in _influenceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = DarkDiaryTheme.theme;
    return Theme(
      data: theme,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
          title: const Text('Настроение'),
          actions: [
            IconButton(
              icon: const Icon(Icons.note_add_outlined),
              tooltip: 'Черновик',
              onPressed: _editDraftNote,
            ),
            const SizedBox(width: 8),
            const DiaryMenuButton(),
          ],
        ),
        body: SafeArea(
          bottom: false,
    child: KeyboardSafeContent(
    child: SingleChildScrollView(
    keyboardDismissBehavior:
    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    min: 0,
                    max: 10,
                    divisions: 10,
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
                  style: theme.textTheme.bodyLarge!.copyWith(
                                      color: const Color(0xFFE6E1E5),
                                    ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _moodCtrl,
                  decoration: InputDecoration(
                    hintText: 'Своё описание настроения',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Подсказка',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const AlertDialog(
                              content: Text('Выбери все подходящие эмоции'),
                          ),
                        );
                      },
                    ),
                  ),
                  onChanged: (_) async => await _save(),
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
    GestureDetector(
    onLongPress: () => _showEmotionHint(emo),
    child: FilterChip(
    label: Text(emo),
    selected: _selected.contains(emo),
    selectedColor: const Color(0xFF4B3B7F),
    checkmarkColor: const Color(0xFFE6E1E5),
      onSelected: (v) async {
        setState(() {
          if (v) {
            _selected.add(emo);
            _influenceCtrls.putIfAbsent(
                emo, () => TextEditingController());
          } else {
            _selected.remove(emo);
            _influenceCtrls.remove(emo)?.dispose();
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
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _influenceCard(),
                ],
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
                    if (!mounted) return;
                    Navigator.pushNamed(
                      context,
                      AchievementsScreenNew.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('Далее: Достижения'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}