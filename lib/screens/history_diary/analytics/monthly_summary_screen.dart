import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../utils/parse_utils.dart';

class MonthlySummaryScreen extends StatefulWidget {
  static const routeName = '/analytics/monthly';
  const MonthlySummaryScreen({Key? key}) : super(key: key);

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  final List<DateTime> _months = [];
  int _selectedIndex = 0;
  List<EntryData> _all = [];
  bool _showRating = true;
  bool _showEnergy = true;
  bool _showSleep = true;
  bool _showSteps = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _hasPrev => _selectedIndex > 0;
  bool get _hasNext => _selectedIndex < _months.length - 1;

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    final months = <DateTime>{};
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    months.add(now);
    for (final e in all) {
      final parts = e.date.split('-');
      if (parts.length != 3) continue;
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d == null || m == null || y == null) continue;
      months.add(DateTime(y, m));
    }
    final sorted = months.toList()..sort();
    final idx = sorted.indexWhere((m) => m.year == now.year && m.month == now.month);
    setState(() {
      _all = all;
      _months
        ..clear()
        ..addAll(sorted);
      _selectedIndex = idx >= 0 ? idx : 0;
    });
  }

  List<EntryData> get _entries {
    if (_months.isEmpty) return [];
    final m = _months[_selectedIndex];
    final start = DateTime(m.year, m.month, 1);
    final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59, 999);
    return _all.where((e) {
      final parts = e.date.split('-');
      if (parts.length != 3) return false;
      final d = int.tryParse(parts[0]);
      final mm = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d == null || mm == null || y == null) return false;
      final dt = DateTime(y, mm, d);
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  double get _avgRating {
    if (_entries.isEmpty) return 0;
    final sum = _entries.map((e) => double.tryParse(e.rating) ?? 0).reduce((a, b) => a + b);
    return sum / _entries.length;
  }

  double get _avgEnergy {
    if (_entries.isEmpty) return 0;
    final sum = _entries.map((e) => double.tryParse(e.energy) ?? 0).reduce((a, b) => a + b);
    return sum / _entries.length;
  }

  double get _avgSleep {
    if (_entries.isEmpty) return 0;
    final sum = _entries.map((e) => ParseUtils.parseHours(e.sleepDuration)).reduce((a, b) => a + b);
    return sum / _entries.length;
  }

  int get _totalSteps => _entries.fold(0, (p, e) => p + (int.tryParse(e.steps) ?? 0));

  @override
  Widget build(BuildContext context) {
    final monthNames = _months.map((m) => DateFormat('LLLL yyyy', 'ru').format(m)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Месячные сводки'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _hasPrev
                        ? () => setState(() => _selectedIndex--)
                        : null,
                  ),
                  Text(monthNames.isEmpty ? '' : monthNames[_selectedIndex]),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _hasNext
                        ? () => setState(() => _selectedIndex++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Оценка'),
                  selected: _showRating,
                  onSelected: (v) => setState(() => _showRating = v),
                ),
                FilterChip(
                  label: const Text('Энергия'),
                  selected: _showEnergy,
                  onSelected: (v) => setState(() => _showEnergy = v),
                ),
                FilterChip(
                  label: const Text('Сон'),
                  selected: _showSleep,
                  onSelected: (v) => setState(() => _showSleep = v),
                ),
                FilterChip(
                  label: const Text('Шаги'),
                  selected: _showSteps,
                  onSelected: (v) => setState(() => _showSteps = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text('Нет данных'))
                  : ListView(
                children: [
                  if (_showRating)
                    _StatTile(label: 'Средняя оценка', value: _avgRating.toStringAsFixed(1)),
                  if (_showEnergy)
                    _StatTile(label: 'Средняя энергия', value: _avgEnergy.toStringAsFixed(1)),
                  if (_showSleep)
                    _StatTile(label: 'Средний сон, ч', value: _avgSleep.toStringAsFixed(1)),
                  if (_showSteps)
                    _StatTile(label: 'Всего шагов', value: _totalSteps.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}