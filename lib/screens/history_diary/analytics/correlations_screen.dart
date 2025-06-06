// lib/screens/history_diary/analytics/correlations_screen.dart

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';

enum _Period { week, month, all }

class CorrelationsScreen extends StatefulWidget {
  static const routeName = '/analytics/correlations';
  const CorrelationsScreen({Key? key}) : super(key: key);

  @override
  State<CorrelationsScreen> createState() => _CorrelationsScreenState();
}

class _CorrelationsScreenState extends State<CorrelationsScreen> {
  List<EntryData> _all = [], _entries = [];
  _Period _period = _Period.week;

  bool _showRating = true;
  bool _showEnergy = true;
  bool _showSleep = true;
  bool _showSteps = true;
  bool _smoothLines = true;

  static const _ratingColor = Colors.green;
  static const _energyColor = Colors.orange;
  static const _sleepColor = Colors.blueAccent;
  static const _stepsColor = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
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
  }

  DateTime _entryDate(EntryData e) {
    final parts = e.date.split('-');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  DateTime? _toDateTime(EntryData e, String hhmm) {
    try {
      final base = _entryDate(e);
      final parts = hhmm.split(':').map(int.parse).toList();
      final bedHour = int.tryParse(e.bedTime.split(':')[0]) ?? parts[0];
      final nextDay = parts[0] < bedHour;
      return DateTime(base.year, base.month, base.day + (nextDay ? 1 : 0), parts[0], parts[1]);
    } catch (_) {
      return null;
    }
  }

  double _sleepHours(EntryData e) {
    try {
      final bed = _toDateTime(e, e.bedTime);
      final wake = _toDateTime(e, e.wakeTime);
      if (bed == null || wake == null || wake.isBefore(bed)) return 0;
      return wake.difference(bed).inMinutes / 60.0;
    } catch (_) {
      return 0;
    }
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_entries.isEmpty) return const Center(child: Text('Нет данных'));

    final dates = <DateTime>[];
    final ratingRaw = <double>[];
    final energyRaw = <double>[];
    final sleepRaw = <double>[];
    final stepsRaw = <double>[];

    for (final e in _entries) {
      dates.add(_entryDate(e));
      ratingRaw.add(double.tryParse(e.rating) ?? 0);
      energyRaw.add(double.tryParse(e.energy) ?? 0);
      sleepRaw.add(_sleepHours(e));
      stepsRaw.add((int.tryParse(e.steps) ?? 0).toDouble());
    }

    final maxRating = ratingRaw.isEmpty ? 0.0 : ratingRaw.reduce(max);
    final maxEnergy = energyRaw.isEmpty ? 0.0 : energyRaw.reduce(max);
    final maxSleep = sleepRaw.isEmpty ? 0.0 : sleepRaw.reduce(max);
    final maxSteps = stepsRaw.isEmpty ? 0.0 : stepsRaw.reduce(max);

    double scale(double v, double maxVal) => maxVal == 0 ? 0 : v * 10 / maxVal;

    final rating = ratingRaw.map((v) => scale(v, maxRating)).toList();
    final energy = energyRaw.map((v) => scale(v, maxEnergy)).toList();
    final sleep = sleepRaw.map((v) => scale(v, maxSleep)).toList();
    final steps = stepsRaw.map((v) => scale(v, maxSteps)).toList();

    final ratingSpots = <FlSpot>[];
    final energySpots = <FlSpot>[];
    final sleepSpots = <FlSpot>[];
    final stepsSpots = <FlSpot>[];

    for (var i = 0; i < _entries.length; i++) {
      final x = i.toDouble();
      ratingSpots.add(FlSpot(x, rating[i]));
      energySpots.add(FlSpot(x, energy[i]));
      sleepSpots.add(FlSpot(x, sleep[i]));
      stepsSpots.add(FlSpot(x, steps[i]));
    }

    final lineBars = <LineChartBarData>[];
    LineChartBarData buildBar(List<FlSpot> spots, Color color) =>
        LineChartBarData(
          spots: spots,
          isCurved: _smoothLines,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 2,
          dotData: FlDotData(show: false),
        );

    if (_showRating) lineBars.add(buildBar(ratingSpots, _ratingColor));
    if (_showEnergy) lineBars.add(buildBar(energySpots, _energyColor));
    if (_showSleep) lineBars.add(buildBar(sleepSpots, _sleepColor));
    if (_showSteps) lineBars.add(buildBar(stepsSpots, _stepsColor));

    final width = max(_entries.length * 40.0, MediaQuery.of(context).size.width);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
                  interval: _entries.length > 7 ? 7 : 1,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= dates.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Transform.rotate(
                        angle: -0.5,
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
                  reservedSize: 24,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 8)),
                  ),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) =>
                Theme.of(context).colorScheme.surfaceVariant,
                getTooltipItems: (spots) {
                  if (spots.isEmpty) return [];
                  final idx = spots.first.x.toInt();
                  final buf = StringBuffer(DateFormat('dd.MM.yyyy').format(dates[idx]));
                  if (_showRating) buf.writeln('\nОценка: ${ratingRaw[idx].toStringAsFixed(1)}');
                  if (_showEnergy) buf.writeln('Энергия: ${energyRaw[idx].toStringAsFixed(1)}');
                  if (_showSleep) buf.writeln('Сон: ${sleepRaw[idx].toStringAsFixed(1)} ч');
                  if (_showSteps) buf.writeln('Шаги: ${stepsRaw[idx].toInt()}');
                  return [LineTooltipItem(buf.toString(), const TextStyle(fontSize: 12))];
                },
              ),
            ),
            lineBarsData: lineBars,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корреляции')),
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
            Wrap(
              alignment: WrapAlignment.center,
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('Оценка', _ratingColor),
                const SizedBox(width: 12),
                _legendItem('Энергия', _energyColor),
                const SizedBox(width: 12),
                _legendItem('Сон', _sleepColor),
                const SizedBox(width: 12),
                _legendItem('Шаги', _stepsColor),
              ],
            ),
            SwitchListTile(
              title: const Text('Сглаживание линий'),
              value: _smoothLines,
              onChanged: (v) => setState(() => _smoothLines = v),
              dense: true,
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildChart(context)),
          ],
        ),
      ),
    );
  }
}