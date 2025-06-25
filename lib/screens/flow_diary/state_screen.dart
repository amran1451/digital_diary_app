import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../main.dart';
import 'emotion_screen.dart';
import '../history_diary/entries_screen.dart';

enum _DateMenu { entries, toggleTheme }

class StateScreen extends StatefulWidget {
  static const routeName = '/state';
  const StateScreen({Key? key}) : super(key: key);

  @override
  State<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {
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

  bool _init = false;

  void _parseExistingActivities() {
    final regex = RegExp(r'^\\s*(.*?)\\s+(\\d+.*)\$');
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      entry =
          ModalRoute.of(context)!.settings.arguments as EntryData;
      bedCtrl =
          TextEditingController(text: entry.bedTime);
      wakeCtrl =
          TextEditingController(text: entry.wakeTime);
      durationCtrl =
          TextEditingController(text: entry.sleepDuration);
      stepsCtrl =
          TextEditingController(text: entry.steps);
      _parseExistingActivities();

      _energy = int.tryParse(entry.energy) ?? 5;
      _energyDesc = _energyLabels[_energy]!;
      // Ensure energy is stored even if the user does not move the slider.
      if (entry.energy.trim().isEmpty) {
        entry.energy = '$_energy';
      }
      DraftService.currentDraft = entry;
      DraftService.saveDraft();

      _init = true;
    }
  }

  @override
  void dispose() {
    bedCtrl.dispose();
    wakeCtrl.dispose();
    durationCtrl.dispose();
    stepsCtrl.dispose();
    for (final c in _activityDurationCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            const Text('🔹 Состояние', style: TextStyle(fontSize: 16)),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: bedCtrl,
              decoration: const InputDecoration(labelText: '⏰ Лёг в:'),
              onChanged: (v) async {
                entry.bedTime = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: wakeCtrl,
              decoration:
                  const InputDecoration(labelText: '⏰ Проснулся в:'),
              onChanged: (v) async {
                entry.wakeTime = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationCtrl,
              decoration:
                  const InputDecoration(labelText: '⏱ Общее время сна'),
              onChanged: (v) async {
                entry.sleepDuration = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stepsCtrl,
              decoration: const InputDecoration(
                labelText: '🚶 Шаги: число',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) async {
                entry.steps = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text('🔥 Активность',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Добавить свою активность',
                    onPressed: _addCustomActivity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: _allActivities.map((act) {
                final selected = _selectedActivities.contains(act);
                return FilterChip(
                  label: Text(act),
                  selected: selected,
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
                );
              }).toList(),
            ),
            if (_selectedActivities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                children: _selectedActivities.map((act) {
                  final ctrl = _activityDurationCtrls
                      .putIfAbsent(act, () => TextEditingController());
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(act)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: ctrl,
                            decoration:
                            const InputDecoration(hintText: 'Длительность'),
                            onChanged: (_) => _updateActivityString(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('⚡️ Энергия: $_energy',
                style: Theme.of(ctx).textTheme.titleMedium),
            Slider(
              value: _energy.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) async {
                _energy = v.toInt();
                entry.energy = '$_energy';
                _energyDesc = _energyLabels[_energy]!;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            Text(_energyDesc,
                style: Theme.of(ctx).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const Spacer(),
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
                    await _updateActivityString();
                    Navigator.pushNamed(
                      ctx,
                      EmotionScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('→ Далее: Настроение'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
