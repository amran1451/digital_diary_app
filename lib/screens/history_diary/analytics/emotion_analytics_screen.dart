// lib/screens/emotion_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';

enum _Period { week, month, all }

class EmotionAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/emotion';
  const EmotionAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<EmotionAnalyticsScreen> createState() => _EmotionAnalyticsScreenState();
}

class _EmotionAnalyticsScreenState extends State<EmotionAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntryData> _allEntries = [];
  List<EntryData> _entries = [];
  _Period _period = _Period.week;
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() => _allEntries = all);
    _applyPeriod();
  }

  void _applyPeriod() {
    final all = _allEntries;
    List<EntryData> selected;
    switch (_period) {
      case _Period.week:
        selected = all.length > 7 ? all.sublist(all.length - 7) : List.from(all);
        break;
      case _Period.month:
        selected = all.length > 30 ? all.sublist(all.length - 30) : List.from(all);
        break;
      case _Period.all:
        selected = List.from(all);
        break;
    }
    setState(() {
      _entries = selected;
      _recomputeCounts();
    });
  }

  /// Нормализуем регистр при подсчёте, чтобы "Радость" и "радость" считались одной
  void _recomputeCounts() {
    final c = <String, int>{};
    for (var e in _entries) {
      final raw = e.mainEmotions.trim();
      if (raw.isEmpty) continue;
      final parts = raw
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty);
      for (var emo in parts) {
        c[emo] = (c[emo] ?? 0) + 1;
      }
    }
    setState(() => _counts = c);
  }

  /// Капитализация первой буквы для отображения
  String _capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  Widget _buildTop5Chart() {
    if (_counts.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final allEntries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = allEntries.take(5).toList();
    final maxCount = top5.first.value.toDouble();

    final groups = List.generate(top5.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: top5[i].value.toDouble(),
            width: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount + 1,
          barGroups: groups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= top5.length) return const SizedBox();
                  return Text(
                    _capitalize(top5[i].key),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value >= meta.max) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
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
      ),
    );
  }

  Widget _buildAllTable() {
    if (_counts.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final allEntries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Эмоция')),
          DataColumn(label: Text('Кол-во')),
        ],
        rows: allEntries
            .map((e) => DataRow(cells: [
                  DataCell(Text(_capitalize(e.key))),
                  DataCell(Text(e.value.toString())),
                ]))
            .toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_counts.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final entries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    const palette = Colors.primaries;
    final sections = List.generate(entries.length, (i) {
      final entry = entries[i];
      final color = palette[i % palette.length];
      final value = entry.value.toDouble();
      final percent = total == 0 ? 0 : (value / total * 100).round();
      return PieChartSectionData(
        value: value,
        color: color,
        title: percent > 0 ? '$percent%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: List.generate(entries.length, (i) {
            final entry = entries[i];
            final color = palette[i % palette.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: color),
                const SizedBox(width: 4),
                Text(
                  '${_capitalize(entry.key)} (${entry.value})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика эмоций'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Топ-5'),
            Tab(text: 'Круговая'),
            Tab(text: 'Все'),
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
            // выбор периода
            Row(
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
            const SizedBox(height: 8),
            const Text(
              'Период считается от сегодняшней даты. Полные данные в разделе "По месяцам".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // контент вкладок
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTop5Chart(),
                  _buildPieChart(),
                  _buildAllTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
