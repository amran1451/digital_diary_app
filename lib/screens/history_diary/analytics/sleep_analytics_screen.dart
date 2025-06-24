// lib/screens/sleep_analytics_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart'; // для переключения темы

enum _Period { week, month, all }

class SleepAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/sleep';
  const SleepAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SleepAnalyticsScreen> createState() => _SleepAnalyticsScreenState();
}

class _SleepAnalyticsScreenState extends State<SleepAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _Period _period = _Period.week;
  List<EntryData> _allEntries = [];
  List<EntryData> _entries = [];

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

  DateTime _entryDate(EntryData e) {
    final parts = e.date.split('-');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  DateTime _toDateTime(EntryData e, String hhmm) {
    final base = _entryDate(e);
    final parts = hhmm.split(':').map(int.parse).toList();
    final bedHour = int.tryParse(e.bedTime.split(':')[0]) ?? parts[0];
    final nextDay = parts[0] < bedHour;
    return DateTime(
      base.year,
      base.month,
      base.day + (nextDay ? 1 : 0),
      parts[0],
      parts[1],
    );
  }

  double _durationHours(EntryData e) {
    try {
      final bed = _toDateTime(e, e.bedTime);
      final wake = _toDateTime(e, e.wakeTime);
      return wake.difference(bed).inMinutes / 60.0;
    } catch (_) {
      return 0.0;
    }
  }

  double get _avgDuration {
    if (_entries.isEmpty) return 0.0;
    final sum = _entries.map(_durationHours).reduce((a, b) => a + b);
    return sum / _entries.length;
  }

  String _fmtH(double v) {
    final h = v.floor();
    final m = ((v - h) * 60).round().toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final screenW = MediaQuery.of(context).size.width;

    // Собираем map<Date, List<duration>>
    final eventsMap = <DateTime, List<int>>{};
    for (final e in _entries) {
      final d = _entryDate(e);
      eventsMap[d] = [ _durationHours(e).round() ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика сна'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(appState.isDark ? Icons.sunny : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDark),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'График'),
            Tab(text: 'Таблица'),
            Tab(text: 'Календарь'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            const Text(
              'Период считается от сегодняшней даты. Полные данные в разделе "По месяцам".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Вкладки
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: _period == _Period.week
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                children: [
                  _buildChartTab(screenW),
                  _buildTableTab(),
                  _buildCalendarTab(eventsMap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(double screenW) {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final bars = _entries.map((e) {
      final dateLabel = DateFormat('dd.MM').format(_entryDate(e));
      final dur = _durationHours(e);
      final barH = max(dur * 8, 2).toDouble();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_fmtH(dur), style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: barH,
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(dateLabel, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (_period == _Period.all) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Средняя длительность: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('${_avgDuration.toStringAsFixed(2)} ч',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: bars),
        ),
      ],
    );
  }

  Widget _buildTableTab() {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Дата')),
          DataColumn(label: Text('Длительность')),
        ],
        rows: _entries.map((e) {
          final date = _entryDate(e);
          final dur = _durationHours(e);
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd.MM.yyyy').format(date))),
            DataCell(Text('${dur.toStringAsFixed(2)} ч')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarTab(Map<DateTime, List<int>> eventsMap) {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    // диапазон от самой ранней до самой поздней даты в eventsMap
    final dates = eventsMap.keys.toList()..sort();
    final first = dates.first;
    final last = dates.last;

    return TableCalendar<int>(
      firstDay: first,
      lastDay: last,
      focusedDay: last,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return eventsMap[key] ?? [];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (ctx, day, events) {
          if (events.isEmpty) return const SizedBox();
          final v = events.first;
          Color bg;
          if (v <= 3) bg = Colors.red.shade200;
          else if (v <= 6) bg = Colors.orange.shade300;
          else if (v <= 8) bg = Colors.lightGreen.shade400;
          else bg = Colors.green.shade600;
          return Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text('$v',
                  style: const TextStyle(fontSize: 12, color: Colors.black)),
            ),
          );
        },
      ),
      onDaySelected: (day, _) {
        final v = (eventsMap[DateTime(day.year, day.month, day.day)] ?? [0]).first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${DateFormat('dd.MM.yyyy').format(day)} — $v ч сна')),
        );
      },
    );
  }
}
