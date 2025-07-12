import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:flutter/services.dart';

import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import '../../theme/dark_diary_theme.dart';

import '../../utils/rating_emoji.dart';
import '../../utils/wellbeing_utils.dart';
import '../../widgets/keyboard_safe_content.dart';

class EntryDetailScreenNew extends StatefulWidget {
  static const routeName = '/entry_detail_new';
  const EntryDetailScreenNew({Key? key}) : super(key: key);

  @override
  State<EntryDetailScreenNew> createState() => _EntryDetailScreenNewState();
}

class _EntryDetailScreenNewState extends State<EntryDetailScreenNew> {
  late EntryData entry;
  final Map<int, bool> _expanded = {};
  bool _editing = false;
  EntryData? _snapshot;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctrls = {};
  int _rating = 5;
  late TextEditingController _ratingReasonCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    entry = ModalRoute.of(context)!.settings.arguments as EntryData;
    _rating = int.tryParse(entry.rating) ?? 5;
    _ratingReasonCtrl = TextEditingController(text: entry.ratingReason);
  }

  Future<void> _pickDate() async {
    final parts = entry.date.split('-');
    DateTime initial;
    try {
      initial = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final newDate =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      setState(() {
        entry.date = newDate;
      });
      await LocalDb.saveOrUpdate(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Дата записи обновлена: $newDate')),
      );
    }
  }

  void _toggle(int i) {
    setState(() => _expanded[i] = !(_expanded[i] ?? false));
  }

  void _initCtrls() {
    final fields = [
      'place',
      'bedTime',
      'wakeTime',
      'sleepDuration',
      'steps',
      'activity',
      'energy',
      'wellBeing',
      'mood',
      'mainEmotions',
      'influence',
      'important',
      'tasks',
      'notDone',
      'thought',
      'development',
      'qualities',
      'growthImprove',
      'pleasant',
      'tomorrowImprove',
      'stepGoal',
      'flow',
    ];
    for (final f in fields) {
      _ctrls[f] = TextEditingController(text: _getField(f));
    }
    _ratingReasonCtrl = TextEditingController(text: entry.ratingReason);
  }

  void _disposeCtrls() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
    _ratingReasonCtrl.dispose();
  }

  String _getField(String name) {
    switch (name) {
      case 'place':
        return entry.place;
      case 'bedTime':
        return entry.bedTime;
      case 'wakeTime':
        return entry.wakeTime;
      case 'sleepDuration':
        return entry.sleepDuration;
      case 'steps':
        return entry.steps;
      case 'activity':
        return entry.activity;
      case 'energy':
        return entry.energy;
      case 'wellBeing':
        return entry.wellBeing ?? '';
      case 'mood':
        return entry.mood;
      case 'mainEmotions':
        return entry.mainEmotions;
      case 'influence':
        return entry.influence;
      case 'important':
        return entry.important;
      case 'tasks':
        return entry.tasks;
      case 'notDone':
        return entry.notDone;
      case 'thought':
        return entry.thought;
      case 'development':
        return entry.development;
      case 'qualities':
        return entry.qualities;
      case 'growthImprove':
        return entry.growthImprove;
      case 'pleasant':
        return entry.pleasant;
      case 'tomorrowImprove':
        return entry.tomorrowImprove;
      case 'stepGoal':
        return entry.stepGoal;
      case 'flow':
        return entry.flow;
    }
    return '';
  }

  void _setField(String name, String value) {
    switch (name) {
      case 'place':
        entry.place = value;
        break;
      case 'bedTime':
        entry.bedTime = value;
        break;
      case 'wakeTime':
        entry.wakeTime = value;
        break;
      case 'sleepDuration':
        entry.sleepDuration = value;
        break;
      case 'steps':
        entry.steps = value;
        break;
      case 'activity':
        entry.activity = value;
        break;
      case 'energy':
        entry.energy = value;
        break;
      case 'wellBeing':
        entry.wellBeing = value.isEmpty ? null : value;
        break;
      case 'mood':
        entry.mood = value;
        break;
      case 'mainEmotions':
        entry.mainEmotions = value;
        break;
      case 'influence':
        entry.influence = value;
        break;
      case 'important':
        entry.important = value;
        break;
      case 'tasks':
        entry.tasks = value;
        break;
      case 'notDone':
        entry.notDone = value;
        break;
      case 'thought':
        entry.thought = value;
        break;
      case 'development':
        entry.development = value;
        break;
      case 'qualities':
        entry.qualities = value;
        break;
      case 'growthImprove':
        entry.growthImprove = value;
        break;
      case 'pleasant':
        entry.pleasant = value;
        break;
      case 'tomorrowImprove':
        entry.tomorrowImprove = value;
        break;
      case 'stepGoal':
        entry.stepGoal = value;
        break;
      case 'flow':
        entry.flow = value;
        break;
    }
  }

  void _startEditing() {
    _snapshot = EntryData.fromMap(entry.toMap());
    _initCtrls();
    setState(() => _editing = true);
  }

  Future<void> _cancelEditing() async {
    if (_snapshot != null) {
      entry = EntryData.fromMap(_snapshot!.toMap());
    }
    _disposeCtrls();
    setState(() => _editing = false);
  }

  Future<void> _saveEditing() async {
    if (!_formKey.currentState!.validate()) return;
    for (final e in _ctrls.entries) {
      _setField(e.key, e.value.text);
    }
    entry.rating = '$_rating';
    entry.ratingReason = _ratingReasonCtrl.text;
    await LocalDb.saveOrUpdate(entry);
    _disposeCtrls();
    setState(() => _editing = false);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    // Showing the SnackBar right before popping this route can trigger
    // "Looking up a deactivated widget's ancestor" assertions. Schedule it
    // for the next frame so that the widget tree has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Изменения сохранены')),
      );
    });
  }

  Widget _buildEditForm(ThemeData theme) {
    return Form(
      key: _formKey,
        child: KeyboardSafeContent(
        child: ListView(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: entry.date),
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Дата'),
                  onTap: _pickDate,
                ),
              ),
              IconButton(onPressed: _pickDate, icon: const Icon(Icons.edit_calendar)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Создано: ${entry.createdAtFormatted}', style: theme.textTheme.bodyMedium),
          TextFormField(
            controller: _ctrls['place'],
            decoration: const InputDecoration(labelText: 'Место'),
          ),
          const SizedBox(height: 16),
          Text(
            '${ratingEmoji[_rating] ?? '🤔'} Оценка дня $_rating',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _rating.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => setState(() => _rating = v.round()),
          ),
          TextFormField(
            controller: _ratingReasonCtrl,
            decoration: const InputDecoration(labelText: 'Причина оценки'),
          ),
          const SizedBox(height: 16),
          ..._ctrls.entries.map((e) {
            final isLong = e.key == 'flow';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextFormField(
                controller: e.value,
                decoration: InputDecoration(labelText: e.key),
                minLines: isLong ? 4 : 1,
                maxLines: isLong ? null : 1,
              ),
            );
          }).toList(),
        ],
      ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final theme = DarkDiaryTheme.theme;

    final sections = _buildSections(entry);
    for (var i = 0; i < sections.length; i++) {
      _expanded.putIfAbsent(i, () => false);
    }

    final buffer = StringBuffer()
      ..writeln('📅 Дата записи: ${entry.date}')
      ..writeln('📝 Создано: ${entry.createdAtFormatted}')
      ..writeln('📍 Место: ${entry.place}')
      ..writeln()
      ..writeln('📊 Оценка дня: ${entry.rating} – ${entry.ratingReason}')
      ..writeln()
      ..writeln('😴 Сон:')
      ..writeln('  • Лёг в: ${entry.bedTime}')
      ..writeln('  • Проснулся в: ${entry.wakeTime}')
      ..writeln('  • Общее: ${entry.sleepDuration}')
      ..writeln('🚶 Шаги: ${entry.steps}')
      ..writeln('🔥 Активность: ${entry.activity}')
      ..writeln('⚡️ Энергия: ${entry.energy}')
      ..writeln('🤒 Самочувствие: ${WellBeingUtils.format(entry.wellBeing)}')
      ..writeln()
      ..writeln('😊 Настроение: ${_formatMood(entry.mood)}')
      ..writeln('🎭 Главные эмоции: ${entry.mainEmotions}')
      ..writeln('💭 Что повлияло на настроение: ${entry.influence}')
      ..writeln()
      ..writeln('✅ Что сделал важного: ${entry.important}')
      ..writeln('📌 Какие задачи выполнил: ${entry.tasks}')
      ..writeln('⏳ Что не успел и почему: ${entry.notDone}')
      ..writeln('💡 Самая важная мысль дня: ${entry.thought}')
      ..writeln()
      ..writeln('📖 Как развивался: ${entry.development}')
      ..writeln('💪 Какие личные качества укрепил: ${entry.qualities}')
      ..writeln('🎯 Что могу улучшить завтра: ${entry.growthImprove}')
      ..writeln()
      ..writeln('🌟 Самый приятный момент дня: ${entry.pleasant}')
      ..writeln('🚀 Что можно улучшить завтра: ${entry.tomorrowImprove}')
      ..writeln('🎯 Один шаг к цели на завтра: ${entry.stepGoal}')
      ..writeln()
      ..writeln('💬 Поток мыслей:')
      ..writeln(entry.flow);

    return Theme(
      data: theme,
        child: WillPopScope(
        onWillPop: () async {
          if (_editing) {
            final res = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Сохранить изменения?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            );
            if (res == true) {
              await _saveEditing();
              return true;
            } else if (res == false) {
                await _cancelEditing();
                return true;
            }
            return false;
          }
          return true;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: DarkDiaryTheme.background,
          appBar: AppBar(
            leadingWidth: 88,
            leading: _editing
                ? TextButton(
                  onPressed: _cancelEditing,
                  child: const Text('Отмена'),
                )
              : null,
            title: const Text('Запись'),
            actions: _editing
            ? [
              TextButton(
                onPressed: _saveEditing,
                child: const Text('Сохранить'),
              ),
            ]
            : [
            IconButton(
              icon:
              Icon(appState.isDark ? Icons.sunny : Icons.nightlight_round),
              onPressed: () => appState.toggleTheme(!appState.isDark),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Скопировать запись',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Запись скопирована в буфер обмена')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              tooltip: 'Изменить дату записи',
              onPressed: _pickDate,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
              onPressed: _startEditing,
            ),
          ],
        ),
        body: _editing
        ? _buildEditForm(theme)
        : ListView.builder(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(8),
          itemCount: sections.length + (entry.notificationsLog.isNotEmpty ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == sections.length && entry.notificationsLog.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ExpansionTile(
                  title: const Text('📌 Что происходило в течение дня'),
                  children: entry.notificationsLog
                      .map((n) => ListTile(
                    leading: Text(_iconForType(n.type)),
                    title: Text(n.text),
                    subtitle: Text(n.answerTime.isNotEmpty ? n.answerTime : n.sentTime),
                  ))
                      .toList(),
                ),
              );
            }
            final s = sections[i];
            final expanded = _expanded[i] ?? false;
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
                            Text('${s.emoji} ${s.title}', style: theme.textTheme.titleMedium),
                            const Spacer(),
                            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          ],
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 12),
                          ...s.fields.map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                text: '${f.label}: ',
                                children: [
                                  TextSpan(
                                    text: f.value.isEmpty ? 'Нет данных' : f.value,
                                    style: f.value.isEmpty
                                        ? theme.textTheme.bodyMedium!.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    )
                                        : theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
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
        _Field(
          'Оценка',
          '${ratingEmoji[int.tryParse(e.rating) ?? -1] ?? '🤔'} '
              '${e.rating} – ${e.ratingReason}',
        ),
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
          WellBeingUtils.format(e.wellBeing),
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

  String _iconForType(String type) {
    switch (type) {
      case 'thought':
        return '🧠';
      case 'activity':
        return '🏃';
      case 'emotion':
        return '🎭';
      default:
        return '📌';
    }
  }
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