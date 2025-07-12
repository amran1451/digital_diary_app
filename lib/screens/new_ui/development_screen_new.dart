import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';
import '../../theme/dark_diary_theme.dart';
import 'focus_screen_new.dart';
import '../../widgets/diary_menu_button.dart';
import '../../widgets/keyboard_safe_content.dart';

class DevelopmentScreenNew extends StatefulWidget {
  static const routeName = '/development-new';
  const DevelopmentScreenNew({Key? key}) : super(key: key);

  @override
  State<DevelopmentScreenNew> createState() => _DevelopmentScreenNewState();
}

class _DevelopmentScreenNewState extends State<DevelopmentScreenNew> {
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
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      devCtrl = TextEditingController(text: entry.development);
      qualitiesCtrl = TextEditingController(text: entry.qualities);
      growthCtrl = TextEditingController(text: entry.growthImprove);
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
                  case 'development':
                    entry.development = v;
                    break;
                  case 'qualities':
                    entry.qualities = v;
                    break;
                  case 'growthImprove':
                    entry.growthImprove = v;
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
        resizeToAvoidBottomInset: true,
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
                  title: const Text('Личностный рост'),
                  actions: const [DiaryMenuButton()],
                ),
        body: SafeArea(
          bottom: false,
    child: KeyboardSafeContent(
    child: SingleChildScrollView(
    keyboardDismissBehavior:
    ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.all(16),
    child: Column(
              children: [
                Center(child: Text('5/6', style: theme.textTheme.labelMedium)),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '📖',
                  title: 'Как развивался?',
                  hint: 'Что узнал, чему научился?',
                  ctrl: devCtrl,
                  field: 'development',
                  info: 'Что узнал, чему научился за день?',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '💪',
                  title: 'Качества',
                  hint: 'Что прокачал?',
                  ctrl: qualitiesCtrl,
                  field: 'qualities',
                  info: 'Что прокачал? терпение, дисциплину и т.д.',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '🎯',
                  title: 'Улучшить завтра',
                  hint: 'Один-единственный шаг',
                  ctrl: growthCtrl,
                  field: 'growthImprove',
                  info: 'Один‑единственный шаг вперед.',
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
                      FocusScreenNew.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('Далее: Итоги'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}