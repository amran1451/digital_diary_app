import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../services/local_db.dart';
import '../../services/quick_note_service.dart';
import '../../services/telegram_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../../theme/dark_diary_theme.dart';
import '../../main.dart';
import '../flow_diary/date_time_screen.dart';
import '../history_diary/entries_screen.dart';
import '../history_diary/entry_detail_screen.dart';

class PreviewScreenNew extends StatefulWidget {
  static const routeName = '/preview-new';
  const PreviewScreenNew({Key? key}) : super(key: key);

  @override
  State<PreviewScreenNew> createState() => _PreviewScreenNewState();
}

class _PreviewScreenNewState extends State<PreviewScreenNew> {
  final _confettiCtrl = ConfettiController(duration: const Duration(seconds: 1));
  final Map<int, bool> _expanded = {};

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(EntryData e, BuildContext ctx) async {
    await LocalDb.saveOrUpdate(e);
    await TelegramService.sendEntry(e);
    _confettiCtrl.play();
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Запись сохранена')),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        ctx,
        DateTimeScreen.routeName,
            (_) => false,
      );
    }
    await DraftService.clearDraft();
    await QuickNoteService.clearForDate(e.date);
  }

  Future<void> _save(EntryData e, BuildContext ctx) async {
    await LocalDb.saveOrUpdate(e);
    ScaffoldMessenger.of(ctx)
        .showSnackBar(const SnackBar(content: Text('Изменения сохранены')));
    await DraftService.clearDraft();
    await QuickNoteService.clearForDate(e.date);
    Navigator.pushNamedAndRemoveUntil(
      ctx,
      EntryDetailScreen.routeName,
          (_) => false,
      arguments: e,
    );
  }

  Future<void> _sharePdf(EntryData e) async {
    final pdf = await PdfService.generatePdf([e]);
    await Printing.sharePdf(bytes: pdf, filename: 'Запись ${e.date}.pdf');
  }

  void _toggle(int i) {
    setState(() => _expanded[i] = !(_expanded[i] ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final entry = ModalRoute.of(context)!.settings.arguments as EntryData;
    final appState = MyApp.of(context);
    final theme = DarkDiaryTheme.theme;

    final sections = _buildSections(entry);
    for (var i = 0; i < sections.length; i++) {
      _expanded.putIfAbsent(i, () => false);
    }

    final validation = entry.important.trim().isEmpty;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
          toolbarHeight: 72,
          title: const Text('Предпросмотр'),
          actions: [
            PopupMenuButton<_DateMenu>(
              onSelected: (item) {
                switch (item) {
                  case _DateMenu.entries:
                    Navigator.pushNamed(context, EntriesScreen.routeName);
                    break;
                  case _DateMenu.toggleTheme:
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
                      appState.isDark
                          ? Icons.sunny
                          : Icons.nightlight_round,
                    ),
                    title: Text(
                      appState.isDark ? 'Светлая тема' : 'Тёмная тема',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _sharePdf(entry),
          child: const Icon(Icons.picture_as_pdf),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (validation)
                  MaterialBanner(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    content: const Text(
                      'Кажется, ты не заполнил раздел Достижения. Вернуться?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Вернуться'),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sections.length,
                    itemBuilder: (ctx, i) {
                      final s = sections[i];
                      final expanded = _expanded[i]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onTap: () => _toggle(i),
                          onLongPress: () {
                            HapticFeedback.lightImpact();
                            _toggle(i);
                          },
                          child: Material(
                            color: const Color(0xFF241E2E),
                            borderRadius: BorderRadius.circular(24),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('${s.emoji} ${s.title}',
                                          style: theme.textTheme.titleMedium),
                                      const Spacer(),
                                      Icon(
                                        expanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                    ],
                                  ),
                                  if (expanded) ...[
                                    const SizedBox(height: 12),
                                    ...s.fields.map((f) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: RichText(
                                        text: TextSpan(
                                          style:
                                          theme.textTheme.bodyMedium,
                                          text: '${f.label}: ',
                                          children: [
                                            TextSpan(
                                              text: f.value.isEmpty
                                                  ? 'Нет данных'
                                                  : f.value,
                                              style: f.value.isEmpty
                                                  ? theme.textTheme.bodyMedium!
                                                  .copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(
                                                      0.5))
                                                  : theme.textTheme.labelLarge!
                                                  .copyWith(
                                                  fontWeight:
                                                  FontWeight
                                                      .w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    height: 72,
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
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(120, 40),
                            backgroundColor: DarkDiaryTheme.primary,
                          ),
                          onPressed: () => entry.localId == null
                              ? _send(entry, context)
                              : _save(entry, context),
                          child: const Text('✈ Отправить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFF9A7BFF),
                  Color(0xFFFFAD5C),
                  Colors.white,
                ],
                numberOfParticles: 20,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Section> _buildSections(EntryData e) => [
    _Section(
      emoji: '📅',
      title: 'Дата и время',
      fields: [
        _Field('Дата', e.date),
        _Field('Создано', e.createdAtFormatted),
        if (e.place.isNotEmpty) _Field('Место', e.place),
      ],
    ),
    _Section(
      emoji: '📊',
      title: 'Оценка',
      fields: [
        _Field('Оценка', '${e.rating} – ${e.ratingReason}'),
      ],
    ),
    _Section(
      emoji: '😴',
      title: 'Сон и активность',
      fields: [
        _Field('Сон', '${e.bedTime} → ${e.wakeTime}'),
        _Field('Длительность', e.sleepDuration),
        _Field('Шаги', e.steps),
        _Field('Активность', e.activity),
        _Field('Энергия', e.energy),
        _Field(
          'Самочувствие',
          e.wellBeing == 'OK' ? 'Всё хорошо' : (e.wellBeing ?? ''),
        ),
      ],
    ),
    _Section(
      emoji: '😊',
      title: 'Настроение и эмоции',
      fields: [
        _Field('Настроение', _formatMood(e.mood)),
        _Field('Эмоции', e.mainEmotions),
        _Field('Влияние', e.influence),
      ],
    ),
    _Section(
      emoji: '✅',
      title: 'Достижения',
      fields: [
        _Field('Важного', e.important),
        _Field('Задачи', e.tasks),
        _Field('Не успел', e.notDone),
        _Field('Мысль', e.thought),
      ],
    ),
    _Section(
      emoji: '📖',
      title: 'Личностный рост',
      fields: [
        _Field('Развитие', e.development),
        _Field('Качества', e.qualities),
        _Field('Улучшить', e.growthImprove),
      ],
    ),
    _Section(
      emoji: '🌟',
      title: 'Планы',
      fields: [
        _Field('Приятное', e.pleasant),
        _Field('Улучшить завтра', e.tomorrowImprove),
        _Field('Шаг к цели', e.stepGoal),
      ],
    ),
    _Section(
      emoji: '💬',
      title: 'Поток мысли',
      fields: [
        _Field('Поток', e.flow),
      ],
    ),
  ];
}

class _Section {
  final String emoji;
  final String title;
  final List<_Field> fields;
  const _Section({required this.emoji, required this.title, required this.fields});
}

class _Field {
  final String label;
  final String value;
  const _Field(this.label, this.value);
}

enum _DateMenu { entries, toggleTheme }

const _moodLabels = <int, String>{
  0: 'Кризис',
  1: 'Безнадёжность',
  2: 'Уныние',
  3: 'Тревога',
  4: 'Напряжение',
  5: 'Нейтрально',
  6: 'Спокойствие',
  7: 'Удовлетворение',
  8: 'Оптимизм',
  9: 'Воодушевление',
  10: 'Эйфория',
};

String _formatMood(String mood) {
  final rating = int.tryParse(mood);
  if (rating == null) return mood;
  final label = _moodLabels[rating];
  return label != null ? '$rating – $label' : mood;
}