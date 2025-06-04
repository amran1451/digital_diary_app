import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../main.dart';
import '../send_diary/preview_screen.dart';
import '../history_diary/entries_screen.dart';

enum _DateMenu { entries, toggleTheme }

class FocusScreen extends StatefulWidget {
  static const routeName = '/focus';
  const FocusScreen({Key? key}) : super(key: key);

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late EntryData entry;
  late TextEditingController pleasantCtrl;
  late TextEditingController tomorrowCtrl;
  late TextEditingController stepCtrl;
  late TextEditingController flowCtrl;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      entry =
          ModalRoute.of(context)!.settings.arguments as EntryData;
      pleasantCtrl =
          TextEditingController(text: entry.pleasant);
      tomorrowCtrl =
          TextEditingController(text: entry.tomorrowImprove);
      stepCtrl =
          TextEditingController(text: entry.stepGoal);
      flowCtrl =
          TextEditingController(text: entry.flow);

      DraftService.currentDraft = entry;
      DraftService.saveDraft();

      _init = true;
    }
  }

  @override
  void dispose() {
    pleasantCtrl.dispose();
    tomorrowCtrl.dispose();
    stepCtrl.dispose();
    flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('🔹 Итоги', style: TextStyle(fontSize: 16)),
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
              controller: pleasantCtrl,
              decoration: InputDecoration(
                labelText: '🌟 Приятный момент',
                suffixIcon: Tooltip(
                  message: 'Что вызвало улыбку?',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.pleasant = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tomorrowCtrl,
              decoration: InputDecoration(
                labelText: '🚀 Улучшить завтра',
                suffixIcon: Tooltip(
                  message: 'Что бы сделал иначе?',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.tomorrowImprove = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stepCtrl,
              decoration: InputDecoration(
                labelText: '🎯 Шаг к цели',
                suffixIcon: Tooltip(
                  message: 'Конкретный шаг вперед.',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.stepGoal = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: flowCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '💬 Поток мысли',
                suffixIcon: Tooltip(
                  message:
                      'Свободное поле для размышлений.',
                  child: const Icon(Icons.info_outline),
                ),
              ),
              onChanged: (v) async {
                entry.flow = v;
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
                      PreviewScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('✉️ Предпросмотр'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
