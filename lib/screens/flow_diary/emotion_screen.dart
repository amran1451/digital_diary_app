import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../main.dart';
import 'achievements_screen.dart';
import '../history_diary/entries_screen.dart';

enum _DateMenu { entries, toggleTheme }

class EmotionScreen extends StatefulWidget {
  static const routeName = '/emotion';
  const EmotionScreen({Key? key}) : super(key: key);

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  late EntryData entry;
  late TextEditingController moodCtrl;
  final Map<String, TextEditingController> _influenceCtrls = {};
  final Set<String> _selectedEmotions = <String>{};
  int? _expandedCategoryIndex;

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
    'Воодушевление': 'Чувство подъёма и энергии.',
    'Восторг': 'Сильная радость и восхищение.',
    'Интерес': 'Любопытство, желание узнать.',
    'Радость': 'Светлое и искреннее переживание счастья, без причины или с ней',
    'Счастье': 'Глубокое удовлетворение.',
    'Лёгкость': 'Свобода от тревог.',
    'Теплота': 'Уют и доброжелательность.',
    'Любовь': 'Сложное состояние привязанности и принятия.',
    'Обожание': 'Идеализация и тёплое чувство к кому-то.',
    'Печаль': 'Мягкая грусть.',
    'Одиночество': 'Чувство изоляции.',
    'Уныние': 'Состояние безрадости.',
    'Потерянность': 'Неуверенность в направлении.',
    'Безысходность': 'Отсутствие надежды.',
    'Ностальгия': 'Теплая память о чём-то утраченном.',
    'Тоска': 'Томление по неясному или утраченному.',
    'Экзистенциальная тоска': 'Чувство пустоты и смысла одновременно.',
    'Меланхолия': 'Эстетичная, тянущая грусть.',
    'Беспокойство': 'Смущённость и волнение.',
    'Неуверенность': 'Сомнения и колебания.',
    'Паника': 'Острая тревога.',
    'Напряжение': 'Сильное внутреннее сжатие.',
    'Предвкушение негатива': 'Ожидание плохого.',
    'Тревога': 'Общее ощущение беспокойства.',
    'Растерянность': 'Потеря ориентиров.',
    'Трепет': 'Ощущение перед чем-то большим или сильным.',
    'Раздражение': 'Мелкая злость.',
    'Обида': 'Чувство несправедливости.',
    'Зависть': 'Чужое вызывает боль из-за сравнения.',
    'Агрессия': 'Готовность нападать.',
    'Неприязнь': 'Отталкивающее чувство.',
    'Фрустрация': 'Неудовлетворение желания.',
    'Сопротивление': 'Отторжение давления или изменений.',
    'Пустота': 'Отсутствие эмоций.',
    'Замерзание': 'Невозможность двигаться.',
    'Онемение': 'Ощущение оцепенения.',
    'Тупик': 'Нет видимого выхода.',
    'Хтонь': 'Глубинное, архаичное чувство.',
    'Спокойствие': 'Ровное состояние.',
    'Устойчивость': 'Чувство опоры.',
    'Принятие': 'Согласие с тем, что есть.',
    'Доверие': 'Уверенность в другом.',
    'Резонанс': 'Отражение чужих эмоций в себе.',
    'Вина': 'Ощущение, что ты причинил вред.',
    'Стыд': 'Чувство, что с тобой что-то не так.',
    'Смущение': 'Дискомфорт от внимания к себе.',
    'Неловкость': 'Неуверенность в действиях.',
    'Амбивалентность': 'Противоречивые эмоции.',
    'Уязвимость': 'Состояние риска быть ранимым.',
    'Катарсис': 'Очищающее эмоциональное освобождение.',
  };
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      entry =
          ModalRoute.of(context)!.settings.arguments as EntryData;
      moodCtrl = TextEditingController(text: entry.mood);
      final regex = RegExp(r'(.*?)\s*[—-]\s*\(([^)]*)\)');
      for (final match in regex.allMatches(entry.influence)) {
        _influenceCtrls[match.group(1)!.trim()] =
            TextEditingController(text: match.group(2)!.trim());
      }

      _selectedEmotions.addAll(
        entry.mainEmotions
            .split(RegExp(r'[;,\n]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
      for (final emo in _selectedEmotions) {
        _influenceCtrls.putIfAbsent(emo, () => TextEditingController());
      }

      _updateInfluenceString(save: false);

      DraftService.currentDraft = entry;
      DraftService.saveDraft();

      _inited = true;
    }
  }

  @override
  void dispose() {
    moodCtrl.dispose();
    for (final c in _influenceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updateInfluenceString({bool save = true}) async {
    final parts = <String>[];
    for (final emo in _selectedEmotions) {
      final text = _influenceCtrls[emo]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      parts.add('$emo — ($text)');
    }
    setState(() => entry.influence = parts.join(', '));
    if (save) {
      DraftService.currentDraft = entry;
      await DraftService.saveDraft();
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            const Text('🔹 Настроение', style: TextStyle(fontSize: 16)),
        actions: [
          PopupMenuButton<_DateMenu>(
            onSelected: (item) {
              switch (item) {
                case _DateMenu.entries:
                  Navigator.pushNamed(context, EntriesScreen.routeName);
                  break;
                case _DateMenu.toggleTheme:
                  final appState = MyApp.of(context);
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
                  MyApp.of(context).isDark
                    ? Icons.sunny
                    : Icons.nightlight_round
                ),
                title: Text( 
                  MyApp.of(context).isDark  
                    ? 'Светлая тема'
                    : 'Тёмная тема'
                ),
              ),
            ),          
          ],
        ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: moodCtrl,
                decoration: InputDecoration(
                  labelText: '😊 Общее настроение',
                    suffixIcon: Tooltip(
                      message:
                        'Одним словом, например: "спокойный день".',
                      child: const Icon(Icons.info_outline),
                    ),
                ),
                onChanged: (v) async {
                  entry.mood = v;
                  DraftService.currentDraft = entry;
                  await DraftService.saveDraft();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('🎭 Главные эмоции',
                style: Theme.of(ctx).textTheme.titleMedium),
              ),
              const SizedBox(height: 4),
              ExpansionPanelList.radio(
                initialOpenPanelValue: _expandedCategoryIndex,
                expansionCallback: (panelIndex, isExpanded) {
                  setState(() {
                    _expandedCategoryIndex = isExpanded ? null : panelIndex as int;
                  });
                },
                children: _emotionCategories.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((categoryEntry) {
                  final index = categoryEntry.key;
                  final cat = categoryEntry.value;
                  final emotions = cat.value;
                  final selectedCount =
                    emotions.where(_selectedEmotions.contains).length;
                  return ExpansionPanelRadio(
                    value: index,
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        title: Text(
                          selectedCount > 0
                              ? '${cat.key} ($selectedCount)'
                              : cat.key,
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        children: emotions.map((emotion) {
                          final selected =
                          _selectedEmotions.contains(emotion);
                          return Tooltip(
                            message: _emotionHints[emotion] ?? '',
                            child: FilterChip(
                              label: Text(emotion),
                              selected: selected,
                              onSelected: (v) async {
                                setState(() {
                                  if (v) {
                                    _selectedEmotions.add(emotion);
                                    _influenceCtrls.putIfAbsent(
                                        emotion, () => TextEditingController());
                                  } else {
                                    _selectedEmotions.remove(emotion);
                                    _influenceCtrls.remove(emotion)?.dispose();
                                  }
                                  entry.mainEmotions =
                                      _selectedEmotions.join(', ');
                                });
                                await _updateInfluenceString();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            if (_selectedEmotions.isNotEmpty)
          Column(
          children: _selectedEmotions.map((emo) {
    final ctrl =
    _influenceCtrls.putIfAbsent(emo, () => TextEditingController());
    return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
    children: [
    Expanded(child: Text(emo)),
    const SizedBox(width: 8),
    Expanded(
    flex: 3,
    child: TextField(
    controller: ctrl,
    decoration: const InputDecoration(
    hintText: 'Что повлияло',
    ),
    onChanged: (_) => _updateInfluenceString(),
    ),
    ),
    ],
    ),
    );
    }).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('← Назад'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DraftService.currentDraft = entry;
                    await DraftService.saveDraft();
                    Navigator.pushNamed(
                      ctx,
                      AchievementsScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('→ Далее: Достижения'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
