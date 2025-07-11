import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';
import '../../theme/dark_diary_theme.dart';
import 'development_screen_new.dart';
import '../../widgets/diary_menu_button.dart';

class AchievementsScreenNew extends StatefulWidget {
  static const routeName = '/achievements-new';
  const AchievementsScreenNew({Key? key}) : super(key: key);

  @override
  State<AchievementsScreenNew> createState() => _AchievementsScreenNewState();
}

class _AchievementsScreenNewState extends State<AchievementsScreenNew> {
  late EntryData entry;
  late TextEditingController importantCtrl;
  late TextEditingController tasksCtrl;
  late TextEditingController notDoneCtrl;
  late TextEditingController thoughtCtrl;
  bool _init = false;
  Map<String, List<QuickNote>> _notes = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      importantCtrl = TextEditingController(text: entry.important);
      tasksCtrl = TextEditingController(text: entry.tasks);
      notDoneCtrl = TextEditingController(text: entry.notDone);
      thoughtCtrl = TextEditingController(text: entry.thought);
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

  Future<void> _applyNote(String field, TextEditingController ctrl, int index) async {
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

  Widget _buildItem({
    required String emoji,
    required String title,
    required String hint,
    required TextEditingController ctrl,
    required String field,
    required String info,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(content: Text(info)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _addNote(field),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              minLines: 2,
              maxLines: null,
              decoration: InputDecoration(hintText: hint),
              onChanged: (v) async {
                switch (field) {
                  case 'important':
                    entry.important = v;
                    break;
                  case 'tasks':
                    entry.tasks = v;
                    break;
                  case 'notDone':
                    entry.notDone = v;
                    break;
                  case 'thought':
                    entry.thought = v;
                    break;
                }
                DraftService.currentDraft = entry;
                await DraftService.saveDraft();
              },
            ),
            DraftNoteHelper.buildNotesList(
              notes: _notes[field] ?? [],
              onApply: (i) => _applyNote(field, ctrl, i),
              onDelete: (i) => _deleteNote(field, i),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = DarkDiaryTheme.theme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
                  title: const Text('Достижения'),
                  actions: const [DiaryMenuButton()],
                ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(child: Text('4/6', style: theme.textTheme.labelMedium)),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '✅',
                  title: 'Что сделал важного?',
                  hint: 'Один-два пункта',
                  ctrl: importantCtrl,
                  field: 'important',
                  info: 'Один‑два пункта ценных дел.',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '📌',
                  title: 'Задачи',
                  hint: 'Что из планов сделано?',
                  ctrl: tasksCtrl,
                  field: 'tasks',
                  info: 'Что из планов сделано?',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '⏳',
                  title: 'Не успел',
                  hint: 'Почему не получилось?',
                  ctrl: notDoneCtrl,
                  field: 'notDone',
                  info: 'Почему не получилось?',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '💡',
                  title: 'Мысль дня',
                  hint: 'Краткая фраза – главный вывод',
                  ctrl: thoughtCtrl,
                  field: 'thought',
                  info: 'Краткая фраза — главный вывод.',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: kElevationToShadow[2],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Назад'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    DraftService.currentDraft = entry;
                    await DraftService.saveDraft();
                    if (!mounted) return;
                    Navigator.pushNamed(
                      context,
                      DevelopmentScreenNew.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('Далее: Личностный рост'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}