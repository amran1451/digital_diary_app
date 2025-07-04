import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../utils/parse_utils.dart';
import '../../../main.dart';

class ActivityAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/activity';
  const ActivityAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<ActivityAnalyticsScreen> createState() => _ActivityAnalyticsScreenState();
}

class _ActivityAnalyticsScreenState extends State<ActivityAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntryData> _all = [], _entries = [];
  String? _month;
  final Map<String, String> _monthNames = {};
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => _entryDate(a).compareTo(_entryDate(b)));
    setState(() => _all = all);
    _updateMonths();
    _apply();
  }

  DateTime _entryDate(EntryData e) {
    final parts = e.date.split('-');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = int.tryParse(parts[1]) ?? 1;
      final y = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(y, m, d);
    }
    return DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
  }

  void _updateMonths() {
    final months = <String>{};
    for (final e in _all) {
      final d = _entryDate(e);
      months.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    }
    final names = <String, String>{};
    for (final m in months) {
      final parts = m.split('-');
      final y = int.parse(parts[0]);
      final mm = int.parse(parts[1]);
      names[m] = DateFormat('LLLL yyyy', 'ru').format(DateTime(y, mm));
    }
    _monthNames
      ..clear()
      ..addAll(names);
  }

  void _apply() {
    final filtered = _month == null
        ? _all
        : _all.where((e) {
      final d = _entryDate(e);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      return key == _month;
    }).toList();
    setState(() {
      _entries = filtered;
      _recomputeCounts();
    });
  }

  void _recomputeCounts() {
    final c = <String, int>{};
    for (final e in _entries) {
      final raw = e.activity.trim();
      if (raw.isEmpty) continue;
      final parts = raw.split(RegExp(r'[,\n]+'));
      for (final p in parts) {
        final act = p.trim().toLowerCase();
        if (act.isEmpty) continue;
        c[act] = (c[act] ?? 0) + 1;
      }
    }
    _counts = c;
  }

  Future<void> _showStats(String act) async {
    final ent = _entries
        .where((e) => e.activity.toLowerCase().contains(act))
        .toList();
    if (ent.isEmpty) return;
    double energy = 0, rating = 0, sleep = 0;
    for (final e in ent) {
      energy += ParseUtils.parseDouble(e.energy);
      rating += double.tryParse(e.rating) ?? 0;
      sleep += ParseUtils.parseHours(e.sleepDuration);
    }
    final avgEnergy = energy / ent.length;
    final avgRating = rating / ent.length;
    final avgSleep = sleep / ent.length;
    final msg = 'Активность: $act\n'
        'Средняя энергия: ${avgEnergy.toStringAsFixed(1)}\n'
        'Средний сон: ${avgSleep.toStringAsFixed(1)} ч\n'
        'Средняя оценка: ${avgRating.toStringAsFixed(1)}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildBarChart() {
    if (_counts.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final entries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final groups = <BarChartGroupData>[];
    final labels = <String>[];
    int maxVal = 0;
    for (var i = 0; i < entries.length; i++) {
      final act = entries[i].key;
      final count = entries[i].value;
      if (count > maxVal) maxVal = count;
      labels.add(act);
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
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            if (event.isInterestedForInteractions &&
                response != null &&
                response.spot != null) {
              final i = response.spot!.touchedBarGroup.x.toInt();
              if (i >= 0 && i < labels.length) {
                _showStats(labels[i]);
              }
            }
          },
        ),
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
                  child:
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
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

  Widget _buildTable() {
    if (_counts.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final entries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Активность')),
          DataColumn(label: Text('Кол-во')),
        ],
        rows: entries
            .map(
              (e) => DataRow(
            cells: [
              DataCell(Text(e.key)),
              DataCell(Text(e.value.toString())),
            ],
            onSelectChanged: (_) => _showStats(e.key),
          ),
        )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика активностей'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'График'),
            Tab(text: 'Таблица'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(appState.isDark ? Icons.sunny : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDark),
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
                  value: _month,
                  hint: const Text('Все месяцы'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Все месяцы'),
                    ),
                    ..._monthNames.entries.map(
                          (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _month = v);
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
                  _buildBarChart(),
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
