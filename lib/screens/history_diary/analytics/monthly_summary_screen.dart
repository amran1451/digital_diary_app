import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  final List<_MonthStats> _stats = [];

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
    final stats = <_MonthStats>[];
    for (final m in sorted) {
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59, 999);
      final entries = all.where((e) {
        final parts = e.date.split('-');
        if (parts.length != 3) return false;
        final d = int.tryParse(parts[0]);
        final mm = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d == null || mm == null || y == null) return false;
        final dt = DateTime(y, mm, d);
        return !dt.isBefore(start) && !dt.isAfter(end);
      }).toList();
      if (entries.isEmpty) {
        stats.add(_MonthStats(month: m, rating: 0, energy: 0, sleep: 0, steps: 0));
        continue;
      }
      final rating = entries.map((e) => double.tryParse(e.rating) ?? 0).reduce((a, b) => a + b) / entries.length;
      final energy = entries.map((e) => double.tryParse(e.energy) ?? 0).reduce((a, b) => a + b) / entries.length;
      final sleep = entries.map((e) => ParseUtils.parseHours(e.sleepDuration)).reduce((a, b) => a + b) / entries.length;
      final steps = entries.fold(0, (p, e) => p + (int.tryParse(e.steps) ?? 0));
      stats.add(_MonthStats(month: m, rating: rating, energy: energy, sleep: sleep, steps: steps));
    }
    setState(() {
      _all = all;
      _months
        ..clear()
        ..addAll(sorted);
      _stats
        ..clear()
        ..addAll(stats);
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Месячные сводки'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Сводка'),
              Tab(text: 'Таблица'),
              Tab(text: 'Графики'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _summaryTab(monthNames),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _tableTab(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _chartTab(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTab(List<String> monthNames) {
    return Column(
      children: [
      SizedBox(
      height: 48,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
      IconButton(
      icon: const Icon(Icons.chevron_left),
      onPressed: _hasPrev ? () => setState(() => _selectedIndex--) : null,
    ),
    Text(monthNames.isEmpty ? '' : monthNames[_selectedIndex]),
    IconButton(
    icon: const Icon(Icons.chevron_right),
    onPressed: _hasNext ? () => setState(() => _selectedIndex++) : null,
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
    );
  }

  Widget _tableTab() {
    if (_stats.isEmpty) return const Center(child: Text('Нет данных'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Месяц')),
          DataColumn(label: Text('Оценка')),
          DataColumn(label: Text('Энергия')),
          DataColumn(label: Text('Сон, ч')),
          DataColumn(label: Text('Шаги')),
        ],
        rows: _stats.map((s) {
          final name = DateFormat('LLL yyyy', 'ru').format(s.month);
          return DataRow(cells: [
            DataCell(Text(name)),
            DataCell(Text(s.rating.toStringAsFixed(1))),
            DataCell(Text(s.energy.toStringAsFixed(1))),
            DataCell(Text(s.sleep.toStringAsFixed(1))),
            DataCell(Text(s.steps.toString())),
          ]);
        }).toList(),
      ),
    );
  }
  static const _ratingColor = Colors.green;
  static const _energyColor = Colors.orange;
  static const _sleepColor = Colors.blueAccent;
  static const _stepsColor = Colors.deepOrange;

  Widget _chartTab(BuildContext context) {
    if (_stats.isEmpty) return const Center(child: Text('Нет данных'));

    final ratingRaw = _stats.map((s) => s.rating).toList();
    final energyRaw = _stats.map((s) => s.energy).toList();
    final sleepRaw = _stats.map((s) => s.sleep).toList();
    final stepsRaw = _stats.map((s) => s.steps.toDouble()).toList();

    final leftValues = <double>[];
    if (_showRating) leftValues.addAll(ratingRaw);
    if (_showEnergy) leftValues.addAll(energyRaw);
    if (_showSleep) leftValues.addAll(sleepRaw);
    final leftMin = leftValues.isEmpty ? 0.0 : leftValues.reduce(min);
    final leftMax = leftValues.isEmpty ? 10.0 : leftValues.reduce(max);

    double scale(double v, double minVal, double maxVal) =>
        maxVal - minVal == 0 ? 5 : (v - minVal) * 10 / (maxVal - minVal);

    final rating = ratingRaw.map((v) => scale(v, leftMin, leftMax)).toList();
    final energy = energyRaw.map((v) => scale(v, leftMin, leftMax)).toList();
    final sleep = sleepRaw.map((v) => scale(v, leftMin, leftMax)).toList();

    final minSteps = stepsRaw.isEmpty ? 0.0 : stepsRaw.reduce(min);
    final maxSteps = stepsRaw.isEmpty ? 0.0 : stepsRaw.reduce(max);
    final steps = stepsRaw.map((v) => scale(v, minSteps, maxSteps)).toList();

    final ratingSpots = <FlSpot>[];
    final energySpots = <FlSpot>[];
    final sleepSpots = <FlSpot>[];
    final stepsSpots = <FlSpot>[];
    final dates = _stats.map((s) => s.month).toList();

    for (var i = 0; i < _stats.length; i++) {
      final x = i.toDouble();
      ratingSpots.add(FlSpot(x, rating[i]));
      energySpots.add(FlSpot(x, energy[i]));
      sleepSpots.add(FlSpot(x, sleep[i]));
      stepsSpots.add(FlSpot(x, steps[i]));
    }

    final bars = <LineChartBarData>[];
    LineChartBarData buildBar(List<FlSpot> spots, Color color) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: true),
        );

    if (_showRating) bars.add(buildBar(ratingSpots, _ratingColor));
    if (_showEnergy) bars.add(buildBar(energySpots, _energyColor));
    if (_showSleep) bars.add(buildBar(sleepSpots, _sleepColor));
    if (_showSteps) bars.add(buildBar(stepsSpots, _stepsColor));

    final width = max(_stats.length * 40.0, MediaQuery.of(context).size.width);

    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Оценка'),
              selected: _showRating,
              onSelected: (v) => setState(() => _showRating = v),
              selectedColor: _ratingColor.withOpacity(0.2),
            ),
            FilterChip(
              label: const Text('Энергия'),
              selected: _showEnergy,
              onSelected: (v) => setState(() => _showEnergy = v),
              selectedColor: _energyColor.withOpacity(0.2),
            ),
            FilterChip(
              label: const Text('Сон'),
              selected: _showSleep,
              onSelected: (v) => setState(() => _showSleep = v),
              selectedColor: _sleepColor.withOpacity(0.2),
            ),
            FilterChip(
              label: const Text('Шаги'),
              selected: _showSteps,
              onSelected: (v) => setState(() => _showSteps = v),
              selectedColor: _stepsColor.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: SizedBox(
              width: width,
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: -0.5,
                  maxY: 10.5,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= dates.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(DateFormat('MM.yy').format(dates[i]), style: const TextStyle(fontSize: 10)),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          if (v < 0 || v > 10) return const SizedBox();
                          final real = leftMin + (v / 10) * (leftMax - leftMin);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(real.toStringAsFixed(1), style: const TextStyle(fontSize: 8)),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: _showSteps,
                        interval: 2,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) {
                          if (v < 0 || v > 10) return const SizedBox();
                          final real = (v / 10) * (maxSteps - minSteps) + minSteps;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(real.round().toString(), style: const TextStyle(fontSize: 8)),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: bars,
                ),
              ),
            ),
          ),
        ),
      ],
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

class _MonthStats {
  final DateTime month;
  final double rating;
  final double energy;
  final double sleep;
  final int steps;
  const _MonthStats({
    required this.month,
    required this.rating,
    required this.energy,
    required this.sleep,
    required this.steps,
  });
}