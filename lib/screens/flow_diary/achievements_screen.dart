import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../main.dart';
import 'development_screen.dart';
import '../history_diary/entries_screen.dart';

enum _DateMenu { entries, toggleTheme }

class AchievementsScreen extends StatefulWidget {
  static const routeName = '/achievements';
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late EntryData entry;
  late TextEditingController importantCtrl;
  late TextEditingController tasksCtrl;
  late TextEditingController notDoneCtrl;
  late TextEditingController thoughtCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      entry =
          ModalRoute.of(context)!.settings.arguments as EntryData;
      importantCtrl =
          TextEditingController(text: entry.important);
      tasksCtrl =
          TextEditingController(text: entry.tasks);
      notDoneCtrl =
          TextEditingController(text: entry.notDone);
      thoughtCtrl =
          TextEditingController(text: entry.thought);

      DraftService.currentDraft = entry;
      DraftService.saveDraft();

      _initialized = true;
    }
  }

  @override
  void dispose() {
    importantCtrl.dispose();
    tasksCtrl.dispose();
    notDoneCtrl.dispose();
    thoughtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            const Text('🔹 Достижения', style: TextStyle(fontSize: 16)),
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
              controller: importantCtrl,
              decoration: InputDecoration(
                labelText: '✅ Что сделал важного?',
                suffixIcon: Tooltip(
                  message:
                      'Один‑два пункта ценных дел.',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.important = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tasksCtrl,
              decoration: InputDecoration(
                labelText: '📌 Задачи',
                suffixIcon: Tooltip(
                  message:
                      'Что из планов сделано?',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.tasks = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notDoneCtrl,
              decoration: InputDecoration(
                labelText: '⏳ Не успел',
                suffixIcon: Tooltip(
                  message:
                      'Почему не получилось?',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.notDone = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: thoughtCtrl,
              decoration: InputDecoration(
                labelText: '💡 Мысль дня',
                suffixIcon: Tooltip(
                  message:
                      'Краткая фраза — главный вывод.',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.thought = v;
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
                      DevelopmentScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('→ Далее: Личностный рост'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
