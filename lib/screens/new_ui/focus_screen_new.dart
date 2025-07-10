import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/quick_note_service.dart';
import '../../utils/draft_note_helper.dart';
import '../../theme/dark_diary_theme.dart';
import '../send_diary/preview_screen.dart';

class FocusScreenNew extends StatefulWidget {
  static const routeName = '/focus-new';
  const FocusScreenNew({Key? key}) : super(key: key);

  @override
  State<FocusScreenNew> createState() => _FocusScreenNewState();
}

class _FocusScreenNewState extends State<FocusScreenNew> {
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
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      pleasantCtrl = TextEditingController(text: entry.pleasant);
      tomorrowCtrl = TextEditingController(text: entry.tomorrowImprove);
      stepCtrl = TextEditingController(text: entry.stepGoal);
      flowCtrl = TextEditingController(text: entry.flow);
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
    int minLines = 2,
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
              minLines: minLines,
              maxLines: null,
              decoration: InputDecoration(hintText: hint),
              onChanged: (v) async {
                switch (field) {
                  case 'pleasant':
                    entry.pleasant = v;
                    break;
                  case 'tomorrowImprove':
                    entry.tomorrowImprove = v;
                    break;
                  case 'stepGoal':
                    entry.stepGoal = v;
                    break;
                  case 'flow':
                    entry.flow = v;
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
        appBar: AppBar(title: const Text('Итоги')),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(child: Text('6/6', style: theme.textTheme.labelMedium)),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '🌟',
                  title: 'Приятный момент',
                  hint: 'Что вызвало улыбку?',
                  ctrl: pleasantCtrl,
                  field: 'pleasant',
                  info: 'Что вызвало улыбку?',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '🚀',
                  title: 'Улучшить завтра',
                  hint: 'Что бы сделал иначе?',
                  ctrl: tomorrowCtrl,
                  field: 'tomorrowImprove',
                  info: 'Что бы сделал иначе?',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '🎯',
                  title: 'Шаг к цели',
                  hint: 'Конкретный шаг вперед.',
                  ctrl: stepCtrl,
                  field: 'stepGoal',
                  info: 'Конкретный шаг вперед.',
                ),
                const SizedBox(height: 8),
                _buildItem(
                  emoji: '💬',
                  title: 'Поток мысли',
                  hint: 'Свободное поле для размышлений',
                  ctrl: flowCtrl,
                  field: 'flow',
                  info: 'Свободное поле для размышлений.',
                  minLines: 4,
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
                    Navigator.pushNamed(
                      context,
                      PreviewScreen.routeName,
                      arguments: entry,
                    );
                  },
                  child: const Text('✉️ Предпросмотр'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}