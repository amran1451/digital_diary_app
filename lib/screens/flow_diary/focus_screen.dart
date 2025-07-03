import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';
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
  Map<String, List<QuickNote>> _notes = {};

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
      QuickNoteService.getNotesForDate(entry.date).then((n) {
        setState(() => _notes = n);
      });

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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Что вызвало улыбку?',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('pleasant'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.pleasant = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['pleasant'] ?? [],
              onApply: (i) => _applyNote('pleasant', pleasantCtrl, i),
              onDelete: (i) => _deleteNote('pleasant', i),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tomorrowCtrl,
              decoration: InputDecoration(
                labelText: '🚀 Улучшить завтра',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Что бы сделал иначе?',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('tomorrowImprove'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.tomorrowImprove = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['tomorrowImprove'] ?? [],
              onApply: (i) => _applyNote('tomorrowImprove', tomorrowCtrl, i),
              onDelete: (i) => _deleteNote('tomorrowImprove', i),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stepCtrl,
              decoration: InputDecoration(
                labelText: '🎯 Шаг к цели',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Конкретный шаг вперед.',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('stepGoal'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.stepGoal = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['stepGoal'] ?? [],
              onApply: (i) => _applyNote('stepGoal', stepCtrl, i),
              onDelete: (i) => _deleteNote('stepGoal', i),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: flowCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '💬 Поток мысли',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Свободное поле для размышлений.',
                      child: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      icon: const Text('🗒'),
                      onPressed: () => _addNote('flow'),
                    ),
                  ],
                ),
              ),
              onChanged: (v) async {
                entry.flow = v;
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes['flow'] ?? [],
              onApply: (i) => _applyNote('flow', flowCtrl, i),
              onDelete: (i) => _deleteNote('flow', i),
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
