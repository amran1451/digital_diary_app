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
  late TextEditingController influenceCtrl;
  final Set<String> _selectedEmotions = <String>{};
  int? _expandedCategoryIndex;

  static const Map<String, List<String>> _emotionCategories = {
    '😄 Радость': [
      'Воодушевление',
      'Восторг',
      'Интерес',
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
      influenceCtrl =
          TextEditingController(text: entry.influence);

      _selectedEmotions.addAll(
        entry.mainEmotions
            .split(RegExp(r'[;,\n]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );

      DraftService.currentDraft = entry;
      DraftService.saveDraft();

      _inited = true;
    }
  }

  @override
  void dispose() {
    moodCtrl.dispose();
    influenceCtrl.dispose();
    super.dispose();
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _emotionCategories.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((categoryEntry) {
                  final index = categoryEntry.key;
                  final cat = categoryEntry.value;
                  final emotions = cat.value;
                  final selectedCount = emotions.where(_selectedEmotions.contains).length;
                  return ExpansionTile(
                    key: PageStorageKey(cat.key),
                    initiallyExpanded: _expandedCategoryIndex == index,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedCategoryIndex = expanded ? index : null;
                      });
                    },
                    title: Text(selectedCount > 0 ? '${cat.key} ($selectedCount)' : cat.key),
                    children: [
                    Wrap(
                    spacing: 8,
                    children: emotions.map((emotion) {
                      final selected = _selectedEmotions.contains(emotion);
                      return Tooltip(
                        message: _emotionHints[emotion] ?? '',
                        child: FilterChip(
                          label: Text(emotion),
                          selected: selected,
                          onSelected: (v) async {
                            setState(() {
                              if (v) {
                                _selectedEmotions.add(emotion);
                              } else {
                                _selectedEmotions.remove(emotion);
                              }
                              entry.mainEmotions = _selectedEmotions.join(', ');
                            });
                            DraftService.currentDraft = entry;
                            await DraftService.saveDraft();
                          },
                        ),
                      );
                    }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: influenceCtrl,
              decoration: InputDecoration(
                labelText: '💭 Что повлияло',
                suffixIcon: Tooltip(
                  message:
                      'Например: "мало общения, тревога за будущее".',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.influence = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
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
