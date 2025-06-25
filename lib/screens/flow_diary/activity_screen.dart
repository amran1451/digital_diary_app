import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/draft_service.dart';
import '../../main.dart';
import 'emotion_screen.dart';

class ActivityScreen extends StatefulWidget {
  static const routeName = '/activity';
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late EntryData entry;
  final Map<String, TextEditingController> _durationCtrls = {};
  final Set<String> _selectedActivities = <String>{};
  final List<String> _allActivities = [
    'Ходьба',
    'Секс',
    'Тренировка',
    'Бег',
    'Растяжка',
    'Домашние дела',
  ];
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      entry = ModalRoute.of(context)!.settings.arguments as EntryData;
      _parseExisting();
      DraftService.currentDraft = entry;
      DraftService.saveDraft();
      _init = true;
    }
  }

  void _parseExisting() {
    final regex = RegExp(r'^\s*(.*?)\s+(\d+.*)$');
    for (final part in entry.activity.split(',')) {
      final item = part.trim();
      if (item.isEmpty) continue;
      final match = regex.firstMatch(item);
      String name;
      String duration;
      if (match != null) {
        name = match.group(1)!.trim();
        duration = match.group(2)!.trim();
      } else {
        name = item;
        duration = '';
      }
      _selectedActivities.add(name);
      _durationCtrls[name] = TextEditingController(text: duration);
      if (!_allActivities.contains(name)) _allActivities.add(name);
    }
  }

  Future<void> _updateActivityString() async {
    final parts = <String>[];
    for (final act in _selectedActivities) {
      final dur = _durationCtrls[act]?.text.trim() ?? '';
      if (dur.isNotEmpty) {
        parts.add('$act $dur');
      } else {
        parts.add(act);
      }
    }
    setState(() => entry.activity = parts.join(', '));
    DraftService.currentDraft = entry;
    await DraftService.saveDraft();
  }

  Future<void> _addCustomActivity() async {
    final nameCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая активность'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: durCtrl,
              decoration: const InputDecoration(labelText: 'Длительность'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _allActivities.add(name);
                _selectedActivities.add(name);
                _durationCtrls[name] = TextEditingController(text: durCtrl.text.trim());
              });
              _updateActivityString();
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _durationCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('🔹 Активность', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить свою активность',
            onPressed: _addCustomActivity,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: _allActivities.map((act) {
                  final selected = _selectedActivities.contains(act);
                  return FilterChip(
                    label: Text(act),
                    selected: selected,
                    onSelected: (v) async {
                      setState(() {
                        if (v) {
                          _selectedActivities.add(act);
                          _durationCtrls.putIfAbsent(act, () => TextEditingController());
                        } else {
                          _selectedActivities.remove(act);
                          _durationCtrls.remove(act)?.dispose();
                        }
                      });
                      await _updateActivityString();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_selectedActivities.isNotEmpty)
                Column(
                  children: _selectedActivities.map((act) {
                    final ctrl = _durationCtrls.putIfAbsent(act, () => TextEditingController());
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(act)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(hintText: 'Длительность'),
                              onChanged: (_) => _updateActivityString(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('← Назад'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _updateActivityString();
                      Navigator.pushNamed(
                        ctx,
                        EmotionScreen.routeName,
                        arguments: entry,
                      );
                    },
                    child: const Text('→ Далее: Настроение'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}