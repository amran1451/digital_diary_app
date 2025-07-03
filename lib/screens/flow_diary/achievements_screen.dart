import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../main.dart';
import 'development_screen.dart';
import '../history_diary/entries_screen.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';

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
  Map<String, List<QuickNote>> _notes = {};

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
      QuickNoteService.getNotesForDate(entry.date).then((n) {
        setState(() => _notes = n);
      });

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

  Future<void> _addNote(String field) async {
    final note = await DraftNoteHelper.addNote(context, entry.date, field);
    if (note != null) {
      setState(() => _notes.putIfAbsent(field, () => []).add(note));
    }
  }

  Future<void> _applyNote(
      String field, TextEditingController ctrl, int index) async {
    final list = _notes[field];
    if (list == null || index >= list.length) return;
    final note = list[index];
    final text = ctrl.text.trim();
    ctrl.text = text.isEmpty ? note.text : '$text\n${note.text}';
    await QuickNoteService.deleteNote(entry.date, field, index);
    setState(() => _notes[field]?.removeAt(index));
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  Future<void> _deleteNote(String field, int index) async {
    await QuickNoteService.deleteNote(entry.date, field, index);
    setState(() => _notes[field]?.removeAt(index));
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Один‑два пункта ценных дел.',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('important'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.important = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['important'] ?? [],
              onApply: (i) => _applyNote('important', importantCtrl, i),
              onDelete: (i) => _deleteNote('important', i),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tasksCtrl,
              decoration: InputDecoration(
                labelText: '📌 Задачи',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Что из планов сделано?',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('tasks'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.tasks = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['tasks'] ?? [],
              onApply: (i) => _applyNote('tasks', tasksCtrl, i),
              onDelete: (i) => _deleteNote('tasks', i),
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Краткая фраза — главный вывод.',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('thought'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.thought = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['thought'] ?? [],
              onApply: (i) => _applyNote('thought', thoughtCtrl, i),
              onDelete: (i) => _deleteNote('thought', i),
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
