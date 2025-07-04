import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../services/cloud_db.dart';
import '../entry_detail_screen.dart';

class ManualHighlightsScreen extends StatefulWidget {
  static const routeName = '/analytics/manual_highlights';
  const ManualHighlightsScreen({Key? key}) : super(key: key);

  @override
  State<ManualHighlightsScreen> createState() => _ManualHighlightsScreenState();
}

class _ManualHighlightsScreenState extends State<ManualHighlightsScreen> {
  List<EntryData> _entries = [];
  final TextEditingController _importCtrl = TextEditingController();

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

  Future<void> _importHighlights() async {
    _importCtrl.clear();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Импорт заметок'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _importCtrl,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Вставьте текст...',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['txt'],
                );
                if (result != null && result.files.isNotEmpty) {
                  final path = result.files.single.path;
                  if (path != null) {
                    final f = File(path);
                    _importCtrl.text = await f.readAsString();
                  }
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Загрузить из файла'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final blocks = _parseBlocks(_importCtrl.text);
    if (blocks.isEmpty) return;

    final existing = await LocalDb.fetchAll();
    final map = {for (var e in existing) e.date: e};

    for (final b in blocks) {
      var entry = map[b.date];
      if (entry == null) {
        final parts = b.date.split('-');
        final dt = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        entry = EntryData(date: b.date, time: '', createdAt: dt);
        map[b.date] = entry;
      }
      entry.highlights = b.lines.join('\n');
      await LocalDb.saveOrUpdate(entry);
      try { await CloudDb.save(entry); } catch (_) {}
    }

    await _load();
  }

  Future<void> _exportHighlights() async {
    final sorted = [..._entries]
      ..sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
    final buf = StringBuffer();
    for (final e in sorted) {
      final lines = e.highlights
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      while (lines.length < 3) {
        lines.add('');
      }
      buf.writeln('📅 ${e.date}');
      for (var i = 0; i < 3; i++) {
        buf.writeln(lines[i]);
      }
      buf.writeln();
    }
    final text = buf.toString().trim();
    if (text.isNotEmpty) {
      await Share.share(text, subject: 'Ключевые моменты');
    }
  }

  Future<void> _clearHighlights() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистить все?'),
        content: const Text('Удалить все ключевые заметки?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await LocalDb.clearHighlights();
      await _load();
    }
  }

  List<_Block> _parseBlocks(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final result = <_Block>[];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().startsWith('копировать') ||
          line.toLowerCase().startsWith('редактировать')) {
        continue;
      }
      if (line.startsWith('📅')) line = line.substring(1).trim();
      final m = RegExp(r'(\d{1,2})[.\-](\d{1,2})[.\-](\d{2,4})').firstMatch(line);
      if (m == null) continue;
      final day = m.group(1)!.padLeft(2, '0');
      final month = m.group(2)!.padLeft(2, '0');
      var year = m.group(3)!;
      if (year.length == 2) year = '20$year';
      final date = '$day-$month-$year';
      final l1 = i + 1 < lines.length ? lines[i + 1].trim() : '';
      final l2 = i + 2 < lines.length ? lines[i + 2].trim() : '';
      final l3 = i + 3 < lines.length ? lines[i + 3].trim() : '';
      result.add(_Block(date, [l1, l2, l3]));
      i += 3;
    }
    return result;
  }

  DateTime _parseDate(String date) {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ключевые заметки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importHighlights,
            tooltip: 'Импорт',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportHighlights,
            tooltip: 'Экспорт',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearHighlights();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Очистить все')),
            ],
          ),
        ],
      ),
      body: _entries.isEmpty
          ? const Center(child: Text('Записей нет'))
          : ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (ctx, i) {
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
              onTap: () async {
                await Navigator.pushNamed(
                  ctx,
                  EntryDetailScreen.routeName,
                  arguments: e,
                );
                await _load();
              },
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

class _Block {
  final String date;
  final List<String> lines;
  _Block(this.date, this.lines);
}