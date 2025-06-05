import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';

enum _Period { week, month, all }

class StepsAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/steps';
  const StepsAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<StepsAnalyticsScreen> createState() => _StepsAnalyticsScreenState();
}

class _StepsAnalyticsScreenState extends State<StepsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntryData> _all = [], _entries = [];
  _Period _period = _Period.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() => _all = all);
    _apply();
  }

  void _apply() {
    setState(() {
      switch (_period) {
        case _Period.week:
          _entries = _all.length > 7
              ? _all.sublist(_all.length - 7)
              : List.from(_all);
          break;
        case _Period.month:
          _entries = _all.length > 30
              ? _all.sublist(_all.length - 30)
              : List.from(_all);
          break;
        case _Period.all:
          _entries = List.from(_all);
          break;
      }
    });
  }

  int get _total =>
      _entries.fold(0, (p, e) => p + (int.tryParse(e.steps) ?? 0));

  int get _max => _entries.isEmpty
      ? 0
      : _entries.map((e) => int.tryParse(e.steps) ?? 0).reduce(max);

  int get _min => _entries.isEmpty
      ? 0
      : _entries.map((e) => int.tryParse(e.steps) ?? 0).reduce(min);

  double get _avg => _entries.isEmpty ? 0 : _total / _entries.length;

  EntryData? get _maxEntry => _entries.isEmpty
      ? null
      : _entries.reduce((a, b) =>
  (int.tryParse(a.steps) ?? 0) > (int.tryParse(b.steps) ?? 0) ? a : b);

  EntryData? get _minEntry => _entries.isEmpty
      ? null
      : _entries.reduce((a, b) =>
  (int.tryParse(a.steps) ?? 0) < (int.tryParse(b.steps) ?? 0) ? a : b);

  Map<String, int> get _activityCounts {
    final map = <String, int>{};
    for (final e in _entries) {
      final raw = e.activity.trim();
      if (raw.isEmpty) continue;
      final parts = raw
          .split(RegExp(r'[;,\n]+'))
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty);
      for (final p in parts) {
        map[p] = (map[p] ?? 0) + 1;
      }
    }
    return map;
  }

  Widget _buildStepsChart(BuildContext context) {
    if (_entries.isEmpty) return const Center(child: Text('Нет данных'));
    final groups = <BarChartGroupData>[];
    final labels = <String>[];
    int maxVal = 0;
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      final val = int.tryParse(e.steps) ?? 0;
      maxVal = max(maxVal, val);
      labels.add(e.date.replaceAll('-', '.'));
      groups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: val.toDouble(),
            width: 16,
            color: val >= 10000
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
        ]),
      );
    }
    final maxY = (maxVal * 1.2).ceil().clamp(10, double.infinity).toDouble();
    final labelStep = max(1, (_entries.length / 10).ceil());
    final angle = _entries.length >= 30 ? -1.1 : -0.5;
    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: groups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length || i % labelStep != 0) {
                  return const SizedBox();
                }
                return Transform.rotate(
                  angle: angle,
                  child: Text(labels[i], style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(v.toInt().toString(),
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (_, resp) {
            if (resp?.spot != null) {
              final idx = resp!.spot!.touchedBarGroupIndex;
              final e = _entries[idx];
              final steps = int.tryParse(e.steps) ?? 0;
              final act = e.activity;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${e.date}: $steps шагов'
                        '${act.isNotEmpty ? ' — $act' : ''}')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildActivityPie(BuildContext context) {
    final counts = _activityCounts;
    if (counts.isEmpty) return const Center(child: Text('Нет данных'));
    final total = counts.values.reduce((a, b) => a + b);
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          color: Colors.primaries[i % Colors.primaries.length],
          title: '${(e.value * 100 / total).toStringAsFixed(1)}%',
          radius: 40,
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 200, child: PieChart(PieChartData(sections: sections))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < entries.length; i++)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 12,
                      height: 12,
                      color: Colors.primaries[i % Colors.primaries.length]),
                  const SizedBox(width: 4),
                  Text(entries[i].key, style: const TextStyle(fontSize: 12)),
                ])
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_entries.isEmpty) return const Center(child: Text('Нет данных'));
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Дата')),
            DataColumn(label: Text('Шаги')),
            DataColumn(label: Text('Активность')),
          ],
          rows: _entries.map((e) {
            return DataRow(cells: [
              DataCell(Text(e.date.replaceAll('-', '.'))),
              DataCell(Text(e.steps)),
              DataCell(Text(e.activity)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MyApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика шагов'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'График'),
            Tab(text: 'Активности'),
            Tab(text: 'Таблица'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(app.isDark ? Icons.sunny : Icons.nightlight_round),
            onPressed: () => app.toggleTheme(!app.isDark),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('7 дней'),
                  selected: _period == _Period.week,
                  onSelected: (_) {
                    setState(() => _period = _Period.week);
                    _apply();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('30 дней'),
                  selected: _period == _Period.month,
                  onSelected: (_) {
                    setState(() => _period = _Period.month);
                    _apply();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Весь период'),
                  selected: _period == _Period.all,
                  onSelected: (_) {
                    setState(() => _period = _Period.all);
                    _apply();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard(label: 'Сумма', value: _total.toDouble()),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Среднее', value: _avg),
                  const SizedBox(width: 8),
                  _StatCard(
                      label: 'Макс',
                      value: _max.toDouble(),
                      date: _maxEntry?.date),
                  const SizedBox(width: 8),
                  _StatCard(
                      label: 'Мин',
                      value: _min.toDouble(),
                      date: _minEntry?.date),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStepsChart(context),
                  _buildActivityPie(context),
                  _buildTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final String? date;
  const _StatCard({
    required this.label,
    required this.value,
    this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final disp = value.isNaN ? '-' : value.toStringAsFixed(0);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(disp,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (date != null && date!.isNotEmpty)
              Text(date!.replaceAll('-', '.'),
                  style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
