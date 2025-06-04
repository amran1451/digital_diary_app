// lib/screens/rating_analytics_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_heatmap_calendar/simple_heatmap_calendar.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart'; // Для переключения темы
import 'package:table_calendar/table_calendar.dart';

enum _Period { week, month, all }

class RatingAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/rating';
  const RatingAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<RatingAnalyticsScreen> createState() => _RatingAnalyticsScreenState();
}

class _RatingAnalyticsScreenState extends State<RatingAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntryData> _allEntries = [];
  List<EntryData> _entries = [];
  _Period _period = _Period.week;
  Map<String, String> _annotations = {}; // dateStr → note

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
    setState(() {
      switch (_period) {
        case _Period.week:
          _entries = _allEntries.length > 7
              ? _allEntries.sublist(_allEntries.length - 7)
              : List.from(_allEntries);
          break;
        case _Period.month:
          _entries = _allEntries.length > 30
              ? _allEntries.sublist(_allEntries.length - 30)
              : List.from(_allEntries);
          break;
        case _Period.all:
          _entries = List.from(_allEntries);
          break;
      }
    });
  }

  double get _minRating => _entries.isEmpty
      ? 0
      : _entries.map((e) => double.tryParse(e.rating) ?? 0).reduce(min);

  double get _maxRating => _entries.isEmpty
      ? 0
      : _entries.map((e) => double.tryParse(e.rating) ?? 0).reduce(max);

  double get _avgRating {
    if (_entries.isEmpty) return 0;
    final sum = _entries
        .map((e) => double.tryParse(e.rating) ?? 0)
        .reduce((a, b) => a + b);
    return sum / _entries.length;
  }

  double get _stdDeviation {
    if (_entries.length < 2) return 0;
    final mean = _avgRating;
    final sumSq = _entries
        .map((e) => pow((double.tryParse(e.rating) ?? 0) - mean, 2))
        .reduce((a, b) => a + b);
    return sqrt(sumSq / (_entries.length - 1));
  }

  Future<void> _shareStats() async {
    final buf = StringBuffer()
      ..writeln(
        'Аналитика оценок за ${_period == _Period.week ? "7 дней" : _period == _Period.month ? "30 дней" : "весь период"}',
      )
      ..writeln('Среднее: ${_avgRating.toStringAsFixed(1)}')
      ..writeln('Мин: ${_minRating.toStringAsFixed(1)}, Макс: ${_maxRating.toStringAsFixed(1)}')
      ..writeln('Дней: ${_entries.length}, SD: ${_stdDeviation.toStringAsFixed(1)}');
    await Share.share(buf.toString(), subject: 'Моя аналитика оценок');
  }

  Future<void> _editAnnotation(DateTime date) async {
    final ds = DateFormat('dd.MM.yyyy').format(date);
    final ctrl = TextEditingController(text: _annotations[ds] ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Примечание $ds'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Добавить заметку'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _annotations[ds] = ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика оценки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'График'),
            Tab(text: 'Таблица'),
            Tab(text: 'Карта'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(appState.isDark ? Icons.sunny : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDark),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться статистикой',
            onPressed: _shareStats,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            // Период
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
            const SizedBox(height: 16),
            // Статкарточки
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _StatCard(label: 'Среднее', value: _avgRating),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Мин', value: _minRating),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Макс', value: _maxRating),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Дней', value: _entries.length.toDouble()),
                  const SizedBox(width: 8),
                  _StatCard(label: 'SD', value: _stdDeviation),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Содержимое вкладок
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _chartTab(context),
                  _tableTab(),
                  _heatmapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartTab(BuildContext context) {
    if (_entries.isEmpty) return const Center(child: Text('Нет данных'));
    final spots = <FlSpot>[];
    final dates = <DateTime>[];
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      final parts = e.date.split('-');
      final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      dates.add(dt);
      spots.add(FlSpot(i.toDouble(), double.tryParse(e.rating) ?? 0));
    }
    final todayIdx = dates.indexWhere((d) =>
        d.year == DateTime.now().year &&
        d.month == DateTime.now().month &&
        d.day == DateTime.now().day);
    final width = max(_entries.length * 40.0, MediaQuery.of(context).size.width);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 1,
        maxScale: 3,
        child: SizedBox(
          width: width,
          height: 300,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 10.2,
              borderData: FlBorderData(
                show: true,
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5),
                  left: BorderSide.none,
                  right: BorderSide.none,
                  bottom: BorderSide.none,
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
              ),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(y1: 0, y2: 3, color: Colors.red.withOpacity(0.15)),
                  HorizontalRangeAnnotation(y1: 3, y2: 6, color: Colors.orange.withOpacity(0.15)),
                  HorizontalRangeAnnotation(y1: 6, y2: 8, color: Colors.lightGreen.withOpacity(0.15)),
                  HorizontalRangeAnnotation(y1: 8, y2: 10.2, color: Colors.green.withOpacity(0.15)),
                ],
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 8,
                    color: Colors.greenAccent.withOpacity(0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (_) => 'Норма 8',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchCallback: (ev, resp) {
                  if (ev is FlLongPressStart && resp?.lineBarSpots?.isNotEmpty == true) {
                    final idx = resp!.lineBarSpots!.first.x.toInt();
                    _editAnnotation(dates[idx]);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final idx = spot.x.toInt();
                    final d = dates[idx];
                    final rating = spot.y.toInt();
                    final ds = DateFormat('dd.MM.yyyy').format(d);
                    final note = _annotations[ds];
                    return LineTooltipItem(
                      '$ds\nРейтинг: $rating' + (note != null ? '\n\n$note' : ''),
                      TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (_entries.length / 7).ceilToDouble().clamp(1, double.infinity),
                    reservedSize: 32,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= dates.length) return const SizedBox();
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
                      if (v > 10) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      if (spot.y == _maxRating) {
                        return FlDotCirclePainter(color: Colors.green, radius: 6);
                      }
                      if (spot.y == _minRating) {
                        return FlDotCirclePainter(color: Colors.red, radius: 6);
                      }
                      if (spot.x.toInt() == todayIdx) {
                        return FlDotCirclePainter(color: Colors.yellow, radius: 6);
                      }
                      return FlDotCirclePainter(color: Theme.of(context).colorScheme.primary, radius: 4);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableTab() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Дата')),
          DataColumn(label: Text('Оценка')),
        ],
        rows: _entries.map((e) {
          return DataRow(cells: [
            DataCell(Text(e.date.replaceAll('-', '.'))),
            DataCell(Text(e.rating)),
          ]);
        }).toList(),
      ),
    );
  }

/// Внутри класса _RatingAnalyticsScreenState

/// Парсер из строки dd-MM-yyyy в DateTime 00:00
DateTime _parseEntryDate(EntryData e) {
  final parts = e.date.split('-');
  return DateTime(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
  );
}

Widget _heatmapTab() {
  if (_entries.isEmpty) return const Center(child: Text('Нет данных'));

  // 1) Собираем оценки по датам, ключи без времени
  final raw = <DateTime, int>{};
  for (var e in _entries) {
    final key = _parseEntryDate(e);
    raw[key] = int.tryParse(e.rating) ?? 0;
  }

  // 2) Вычисляем диапазон от первой до последней даты записи
  final allKeys = raw.keys.toList()..sort();
  final start = allKeys.first;
  final end   = allKeys.last;

  // 3) Заполняем каждый день в диапазоне (если оценки нет – выдаём 0)
  final data = <DateTime,int>{};
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    data[d] = raw[d] ?? 0;
  }

  return TableCalendar(
    firstDay: start,
    lastDay: end,
    focusedDay: end,
    startingDayOfWeek: StartingDayOfWeek.monday,
    headerStyle: const HeaderStyle(
      formatButtonVisible: false,
      titleCentered: true,
    ),
    calendarStyle: const CalendarStyle(outsideDaysVisible: false),
    daysOfWeekStyle: const DaysOfWeekStyle(
      weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
      weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    ),
    calendarBuilders: CalendarBuilders(
      defaultBuilder: (ctx, date, _) {
        final rating = data[DateTime(date.year, date.month, date.day)]!;
        final color = rating <= 3
          ? Colors.red.shade200
          : rating <= 6
            ? Colors.orange.shade300
            : rating <= 8
              ? Colors.lightGreen.shade400
              : Colors.green.shade600;
        return Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text('${date.day}', style: const TextStyle(fontSize: 12)),
        );
      },
      todayBuilder: (ctx, date, _) {
        final rating = data[DateTime(date.year, date.month, date.day)]!;
        final color = rating <= 3
          ? Colors.red.shade200
          : rating <= 6
            ? Colors.orange.shade300
            : rating <= 8
              ? Colors.lightGreen.shade400
              : Colors.green.shade600;
        return Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text('${date.day}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        );
      },
      outsideBuilder: (ctx, date, _) => const SizedBox.shrink(),
    ),
    onDaySelected: (date, _) {
      final ds = DateFormat('dd.MM.yyyy').format(date);
      final r  = data[DateTime(date.year, date.month, date.day)]!;
      final note = _annotations[ds];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Дата: $ds — оценка: $r' + (note != null ? '\n$note' : ''))),
      );
    },
  );
}





}

/// Карточка статистики
class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  const _StatCard({required this.label, required this.value, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final disp = value.isNaN ? '-' : value.toStringAsFixed(1);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              disp,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
