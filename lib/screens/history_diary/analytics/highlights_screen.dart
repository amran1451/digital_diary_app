import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../services/highlight_service.dart';

const _llmPrompt =
    'У тебя есть текст дневниковой записи о событиях и мыслях за день.\n'
    'Пожалуйста, кратко (не более 2–3 слов каждое) выдели три самых важных (ключевых) момента из этого текста — что было главным в этом дне.\n'
    'Ответи массивом из трёх строк.\nЕсли не хватает данных, верни столько, сколько есть.';

enum _Period { week, month, all }

class HighlightsScreen extends StatefulWidget {
  static const routeName = '/analytics/highlights';
  const HighlightsScreen({Key? key}) : super(key: key);

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  List<EntryData> _all = [], _entries = [];
  _Period _period = _Period.week;
  List<String> _highlights = [];
  List<String> _filtered = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() => _all = all);
    _applyPeriod();
  }

  void _applyPeriod() {
    setState(() {
      switch (_period) {
        case _Period.week:
          _entries = _all.length > 7 ? _all.sublist(_all.length - 7) : List.from(_all);
          break;
        case _Period.month:
          _entries = _all.length > 30 ? _all.sublist(_all.length - 30) : List.from(_all);
          break;
        case _Period.all:
          _entries = List.from(_all);
          break;
      }
    });
    _generate();
  }

  Future<void> _generate() async {
    if (_entries.isEmpty) {
      setState(() => _highlights = []);
      _applySearch();
      return;
    }
    setState(() => _loading = true);
    final text = _entries.map((e) => e.flow).join('\n');
    try {
      final res = await HighlightService.extractHighlights(
        flowText: text,
        prompt: _llmPrompt,
        maxHighlights: 3,
      );
      setState(() => _highlights = res);
    } catch (_) {
      setState(() => _highlights = []);
    }
    _applySearch();
    setState(() => _loading = false);
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_highlights);
      } else {
        _filtered = _highlights.where((h) => h.toLowerCase().contains(q)).toList();
      }
    });
  }

  Future<void> _share() async {
    if (_highlights.isEmpty) return;
    await Share.share(_highlights.join('\n'), subject: 'Ключевые моменты');
  }

  Future<void> _edit() async {
    final ctrls = List.generate(3, (i) => TextEditingController(text: i < _highlights.length ? _highlights[i] : ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Редактировать'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => TextField(
              controller: ctrls[i],
              decoration: InputDecoration(labelText: 'Хайлайт ${i + 1}'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _highlights = ctrls.map((c) => c.text).where((s) => s.trim().isNotEmpty).toList());
      _applySearch();
    }
  }

  String _snippet(String highlight) {
    final text = _entries.map((e) => e.flow).join(' ');
    final lower = text.toLowerCase();
    final idx = lower.indexOf(highlight.toLowerCase());
    if (idx < 0) {
      return text.substring(0, min(50, text.length));
    }
    final start = max(0, idx - 25);
    final end = min(text.length, idx + highlight.length + 25);
    return text.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ключевые моменты'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _generate),
          IconButton(icon: const Icon(Icons.share), onPressed: _share),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('7 дней'),
                  selected: _period == _Period.week,
                  onSelected: (_) {
                    setState(() => _period = _Period.week);
                    _applyPeriod();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('30 дней'),
                  selected: _period == _Period.month,
                  onSelected: (_) {
                    setState(() => _period = _Period.month);
                    _applyPeriod();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Весь период'),
                  selected: _period == _Period.all,
                  onSelected: (_) {
                    setState(() => _period = _Period.all);
                    _applyPeriod();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _edit,
                child: const Text('✏️ Редактировать'),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Нет ключевых моментов'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _generate,
                              child: const Text('Сгенерировать'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final h = _filtered[i];
                          final snippet = _snippet(h);
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.star),
                              title: Text(
                                h,
                                textAlign: TextAlign.center,
                              ),
                              subtitle: Text(
                                snippet,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}