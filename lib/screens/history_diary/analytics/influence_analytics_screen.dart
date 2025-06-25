import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';

enum _Period { week, month, all }

class InfluenceAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/influence';
  const InfluenceAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<InfluenceAnalyticsScreen> createState() => _InfluenceAnalyticsScreenState();
}

class _InfluenceAnalyticsScreenState extends State<InfluenceAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntryData> _all = [], _entries = [];
  _Period _period = _Period.week;
  String? _emotion;
  List<String> _emotions = [];
  Map<String, int> _reasonCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() => _all = all);
    _apply();
  }

  void _apply() {
    List<EntryData> list;
    switch (_period) {
      case _Period.week:
        list = _all.length > 7 ? _all.sublist(_all.length - 7) : List.from(_all);
        break;
      case _Period.month:
        list = _all.length > 30 ? _all.sublist(_all.length - 30) : List.from(_all);
        break;
      case _Period.all:
        list = List.from(_all);
        break;
    }
    setState(() {
      _entries = list;
      _recompute();
    });
  }

  DateTime _entryDate(EntryData e) {
    final parts = e.date.split('-');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  void _recompute() {
    final counts = <String, int>{};
    final emotions = <String>{};
    final regex = RegExp(r'(.*?)\\s*[—-]\\s*(\\([^)]*\\)|[^,]+)(?:,|$)');
    for (final e in _entries) {
      for (final m in regex.allMatches(e.influence)) {
        final emo = m.group(1)!.trim();
        var reason = m.group(2)!.trim();
        if (reason.startsWith('(') && reason.endsWith(')')) {
          reason = reason.substring(1, reason.length - 1).trim();
        }
        emotions.add(emo);
        if (_emotion == null || _emotion == emo) {
          counts[reason] = (counts[reason] ?? 0) + 1;
        }
      }
    }
    _reasonCounts = counts;
    _emotions = emotions.toList()..sort();
  }

  Widget _buildReasonChart() {
    if (_reasonCounts.isEmpty) return const Center(child: Text('Нет данных'));
    final entries = _reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final groups = <BarChartGroupData>[];
    final labels = <String>[];
    int maxVal = 0;
    for (var i = 0; i < entries.length; i++) {
      final reason = entries[i].key;
      final count = entries[i].value;
      if (count > maxVal) maxVal = count;
      labels.add(reason);
      groups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            width: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ]),
      );
    }
    final maxY = (maxVal * 1.2).ceil().clamp(1, double.infinity).toDouble();
    final labelStep = max(1, (entries.length / 10).ceil());
    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: groups,
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                if (v > maxY) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length || i % labelStep != 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Text(labels[i], style: const TextStyle(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_entries.isEmpty) return const Center(child: Text('Нет данных'));
    final daily = <DateTime, int>{};
    final regex = RegExp(r'(.*?)\\s*[—-]\\s*(\\([^)]*\\)|[^,]+)(?:,|$)');
    for (final e in _entries) {
      int count = 0;
      for (final m in regex.allMatches(e.influence)) {
        final emo = m.group(1)!.trim();
        if (_emotion != null && _emotion != emo) continue;
        count++;
      }
      if (count == 0) continue;
      final d = _entryDate(e);
      daily[d] = (daily[d] ?? 0) + count;
    }
    if (daily.isEmpty) return const Center(child: Text('Нет данных'));
    final dates = daily.keys.toList()..sort();
    final values = dates.map((d) => daily[d]!.toDouble()).toList();
    final spots = List.generate(dates.length, (i) => FlSpot(i.toDouble(), values[i]));
    final maxV = values.reduce(max);
    final labelStep = max(1, (dates.length / 10).ceil());
    return LineChart(
      LineChartData(
        maxY: maxV + 1,
        minY: 0,
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, barWidth: 2),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= dates.length || i % labelStep != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Text(DateFormat('dd.MM').format(dates[i]), style: const TextStyle(fontSize: 10)),
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
                if (v > maxV + 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildTable() {
    if (_reasonCounts.isEmpty) return const Center(child: Text('Нет данных'));
    final entries = _reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Причина')),
          DataColumn(label: Text('Кол-во')),
        ],
        rows: entries
            .map(
              (e) => DataRow(cells: [
            DataCell(Text(e.key)),
            DataCell(Text(e.value.toString())),
          ]),
        )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MyApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Что повлияло'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Причины'),
            Tab(text: 'Динамика'),
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
                DropdownButton<String?>(
                  value: _emotion,
                  hint: const Text('Все эмоции'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все эмоции')),
                    ..._emotions.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                  ],
                  onChanged: (v) {
                    setState(() => _emotion = v);
                    _recompute();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('7 дней'),
                  selected: _period == _Period.week,
                  onSelected: (_) {
                    setState(() => _period = _Period.week);
                    _apply();
                  },
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('30 дней'),
                  selected: _period == _Period.month,
                  onSelected: (_) {
                    setState(() => _period = _Period.month);
                    _apply();
                  },
                ),
                const SizedBox(width: 4),
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReasonChart(),
                  _buildLineChart(),
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