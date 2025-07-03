import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';
import '../../main.dart';
import 'focus_screen.dart';
import '../history_diary/entries_screen.dart';

enum _DateMenu { entries, toggleTheme }

class DevelopmentScreen extends StatefulWidget {
  static const routeName = '/development';
  const DevelopmentScreen({Key? key}) : super(key: key);

  @override
  State<DevelopmentScreen> createState() =>
      _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen> {
  late EntryData entry;
  late TextEditingController devCtrl;
  late TextEditingController qualitiesCtrl;
  late TextEditingController growthCtrl;
  bool _init = false;
  Map<String, List<QuickNote>> _notes = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      entry =
          ModalRoute.of(context)!.settings.arguments as EntryData;
      devCtrl =
          TextEditingController(text: entry.development);
      qualitiesCtrl =
          TextEditingController(text: entry.qualities);
      growthCtrl =
          TextEditingController(text: entry.growthImprove);

      DraftService.currentDraft = entry;
      DraftService.saveDraft();
      QuickNoteService.getNotesForDate(entry.date).then((n) {
        setState(() => _notes = n);
      });

      _init = true;
    }
  }

  @override
  void dispose() {
    devCtrl.dispose();
    qualitiesCtrl.dispose();
    growthCtrl.dispose();
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
        title: const Text(
          '🔹 Личностный рост',
          style: TextStyle(fontSize: 16),
        ),
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
              controller: devCtrl,
              decoration: InputDecoration(
                labelText: '📖 Как развивался?',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Что узнал, чему научился за день?',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('development'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.development = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['development'] ?? [],
              onApply: (i) => _applyNote('development', devCtrl, i),
              onDelete: (i) => _deleteNote('development', i),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qualitiesCtrl,
              decoration: InputDecoration(
                labelText: '💪 Качества',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Что прокачал? терпение, дисциплину и т.д.',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('qualities'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.qualities = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['qualities'] ?? [],
              onApply: (i) => _applyNote('qualities', qualitiesCtrl, i),
              onDelete: (i) => _deleteNote('qualities', i),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: growthCtrl,
              decoration: InputDecoration(
                labelText: '🎯 Улучшить завтра',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Один‑единственный шаг вперед.',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('growthImprove'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.growthImprove = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['growthImprove'] ?? [],
              onApply: (i) => _applyNote('growthImprove', growthCtrl, i),
              onDelete: (i) => _deleteNote('growthImprove', i),
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
                      FocusScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('→ Далее: Итоги'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
