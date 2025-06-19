import 'package:flutter/material.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../services/cloud_db.dart';

class ManualHighlightsScreen extends StatefulWidget {
  static const routeName = '/analytics/manual_highlights';
  const ManualHighlightsScreen({Key? key}) : super(key: key);

  @override
  State<ManualHighlightsScreen> createState() => _ManualHighlightsScreenState();
}

class _ManualHighlightsScreenState extends State<ManualHighlightsScreen> {
  List<EntryData> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() => _entries = all);
  }

  Future<void> _editEntry(EntryData e) async {
    final current = e.highlights.split('\n');
    final ctrls = List.generate(
      3,
          (i) => TextEditingController(text: i < current.length ? current[i] : ''),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Планы/заметки ${e.date}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
                (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: ctrls[i],
                decoration: InputDecoration(labelText: 'Строка ${i + 1}'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final lines = ctrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      e.highlights = lines.join('\n');
      await LocalDb.saveOrUpdate(e);
      try { await CloudDb.save(e); } catch (_) {}
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ключевые заметки')),
      body: _entries.isEmpty
          ? const Center(child: Text('Записей нет'))
          : ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (_, i) {
          final e = _entries[i];
          final lines = e.highlights
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList();
          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(e.date),
              subtitle: lines.isEmpty
                  ? null
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines.map((l) => Text(l)).toList(),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editEntry(e),
              ),
            ),
          );
        },
      ),
    );
  }
}