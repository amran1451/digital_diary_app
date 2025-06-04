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
  late TextEditingController mainEmotionsCtrl;
  late TextEditingController influenceCtrl;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      entry =
          ModalRoute.of(context)!.settings.arguments as EntryData;
      moodCtrl = TextEditingController(text: entry.mood);
      mainEmotionsCtrl =
          TextEditingController(text: entry.mainEmotions);
      influenceCtrl =
          TextEditingController(text: entry.influence);

      DraftService.currentDraft = entry;
      DraftService.saveDraft();

      _inited = true;
    }
  }

  @override
  void dispose() {
    moodCtrl.dispose();
    mainEmotionsCtrl.dispose();
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
      body: Padding(
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
            TextField(
              controller: mainEmotionsCtrl,
              decoration: InputDecoration(
                labelText: '🎭 Главные эмоции',
                suffixIcon: Tooltip(
                  message:
                      '1–3 эмоции: радость, тревога и т.д.',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.mainEmotions = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
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
    );
  }
}
