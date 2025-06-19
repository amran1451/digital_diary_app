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
  late TextEditingController activityCtrl;

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
      activityCtrl =
          TextEditingController(text: entry.activity);

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
    activityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

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
            TextField(
              controller: activityCtrl,
              decoration: InputDecoration(
                labelText: '🔥 Активность',
                suffixIcon: Tooltip(
                  message:
                      'Пример: тренировка 40 мин, прогулка 30 мин.',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.activity = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
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
