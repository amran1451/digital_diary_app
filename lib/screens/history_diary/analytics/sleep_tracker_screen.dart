// lib/screens/sleep_tracker_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';

enum _Period { week, month, all }

class SleepTrackerScreen extends StatefulWidget {
  static const routeName = '/analytics/sleep_tracker';
  const SleepTrackerScreen({Key? key}) : super(key: key);

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with SingleTickerProviderStateMixin {
  // Width of the left column with dates. Enough to fit "12.05" without
  // wasting extra space.
  static const double _dayWidth = 36;
  static const double _leftSpacing = 4;
  // Spacing between the column with dates and the chart area
  static const double _betweenSpacing = 8;
  // Right padding so the last hour label is fully visible
  static const double _rightSpacing = 8;
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();

  List<EntryData> _allEntries = [];
  List<EntryData> _entries = [];
  _Period _period = _Period.week;

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

  DateTime? _toDateTime(EntryData e, String hhmm) {
    try {
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
    } catch (_) {
      return null;
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hч $mм';
  }

  int? _parseMinutes(String s) {
    final p = s.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  String _fmtTime(int mins) {
    final h = (mins ~/ 60) % 24;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Duration get _avgSleepDuration {
    final list = _entries
        .map((e) {
      final bed = _toDateTime(e, e.bedTime);
      final wake = _toDateTime(e, e.wakeTime);
      if (bed == null || wake == null || wake.isBefore(bed)) return null;
      return wake.difference(bed);
    })
        .whereType<Duration>()
        .toList();
    if (list.isEmpty) return Duration.zero;
    final total = list.fold<int>(0, (p, d) => p + d.inMinutes);
    return Duration(minutes: (total / list.length).round());
  }

  int get _avgWakeMinutes {
    final list = _entries
        .map((e) => _parseMinutes(e.wakeTime))
        .whereType<int>()
        .toList();
    if (list.isEmpty) return 0;
    final sum = list.reduce((a, b) => a + b);
    return (sum / list.length).round();
  }

  int get _avgBedMinutes {
    final vals = _entries
        .map((e) => _parseMinutes(e.bedTime))
        .whereType<int>()
        .toList();
    if (vals.isEmpty) return 0;
    double sinSum = 0, cosSum = 0;
    for (final v in vals) {
      final ang = v / 1440 * 2 * pi;
      sinSum += sin(ang);
      cosSum += cos(ang);
    }
    final ang = atan2(sinSum / vals.length, cosSum / vals.length);
    final res = ang >= 0 ? ang : ang + 2 * pi;
    return (res * 1440 / (2 * pi)).round();
  }

  void _showDetails(EntryData e) {
    final bed = _toDateTime(e, e.bedTime);
    final wake = _toDateTime(e, e.wakeTime);
    if (bed == null || wake == null) return;
    final dur = wake.difference(bed);
    final msg =
        '${DateFormat('dd.MM').format(_entryDate(e))} — ${_formatDuration(dur)}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildAxis(double width, double hourWidth) {
    final labels = [
      for (int h = 18; h <= 22; h += 2) '$h',
      '0',
      for (int h = 2; h <= 16; h += 2) '$h',
    ];
    return Padding(
      padding: const EdgeInsets.only(
        left: _leftSpacing,
        right: _rightSpacing,
      ),
      child: Row(
        children: [
          const SizedBox(width: _dayWidth),
          const SizedBox(width: _betweenSpacing),
      SizedBox(
            width: width,
            height: 20,
            child: Stack(
              children: [
              // first label
              Positioned(
              left: -hourWidth,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: hourWidth * 2,
                child: Center(
                  child: Text(
                    labels.first,
                    style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            // middle labels
            Positioned.fill(
              left: hourWidth,
              right: hourWidth,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
              for (int i = 1; i < labels.length - 1; i++)
              SizedBox(
              width: hourWidth * 2,
              child: Center(
                child: Text(
                  labels[i],
                  style: const TextStyle(fontSize: 10),
                ),
                          ),
                        ),
                  ],
              ),
                ),
            // last label
            Positioned(
              right: -hourWidth,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: hourWidth * 2,
                child: Center(
                  child: Text(
                    labels.last,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                  ),
            ),
          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(EntryData e, double width, double hourWidth) {
    final bed = _toDateTime(e, e.bedTime);
    final wake = _toDateTime(e, e.wakeTime);
    final day = DateFormat('dd.MM').format(_entryDate(e));

    if (bed == null || wake == null || wake.isBefore(bed)) {
      return Padding(
        padding: const EdgeInsets.only(
          left: _leftSpacing,
          right: _rightSpacing,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _dayWidth,
              height: 24,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(day, softWrap: false),
              ),
            ),
            const SizedBox(width: _betweenSpacing),
            SizedBox(
              width: width,
              height: 24,
              child: const Center(child: Text('не спал ☹️')),
            ),
          ],
        ),
      );
    }

    final base = DateTime(
      bed.year,
      bed.month,
      bed.day - (bed.hour < 18 ? 1 : 0),
      18,
    );
    final startMin = bed.difference(base).inMinutes.toDouble();
    final endMin = wake.difference(base).inMinutes.toDouble();
    final left = startMin / 60 * hourWidth;
    final right = endMin / 60 * hourWidth;
    final dur = wake.difference(bed);

    final leftClamped = left.clamp(0.0, width);
    final barWidth = (right.clamp(0.0, width) - leftClamped).clamp(0.0, width);

    return Padding(
      padding: const EdgeInsets.only(
        left: _leftSpacing,
        right: _rightSpacing,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _dayWidth,
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(day, softWrap: false),
            ),
          ),
          const SizedBox(width: _betweenSpacing),
          GestureDetector(
            onTap: () => _showDetails(e),
            child: SizedBox(
    width: width,
    height: 24,
    child: Stack(
    children: [
    for (int i = 0; i <= 22; i++)
    Positioned(
    left: i * hourWidth - 0.5,
    top: 0,
    bottom: 0,
    child: Container(
    width: 1,
    color: Colors.grey.withOpacity(0.3)),
    ),
                  Positioned(
    left: leftClamped,
    top: 2,
    width: barWidth,
    bottom: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatDuration(dur),
                        style:
                        const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
    ],
    ),
            ),
          ),
    ],
    ),
    );
  }

  Widget _buildTrackerTab(double width, double hourWidth) {
    return Column(
      children: [
        _buildAxis(width, hourWidth),
        const SizedBox(height: 4),
        Expanded(
          child: _entries.isEmpty
              ? const Center(child: Text('Нет данных'))
              : Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in _entries) _buildRow(e, width, hourWidth),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final dur = _avgSleepDuration;
    final wake = _fmtTime(_avgWakeMinutes);
    final bed = _fmtTime(_avgBedMinutes);
    int? earliestBed;
    DateTime? earliestBedDate;
    int? latestBed;
    DateTime? latestBedDate;
    int? earliestWake;
    DateTime? earliestWakeDate;
    int? latestWake;
    DateTime? latestWakeDate;
    Duration? shortest;
    DateTime? shortestDate;
    Duration? longest;
    DateTime? longestDate;

    for (final e in _entries) {
      final bedMin = _parseMinutes(e.bedTime);
      final wakeMin = _parseMinutes(e.wakeTime);
      final durEntry = _toDateTime(e, e.bedTime) != null &&
          _toDateTime(e, e.wakeTime) != null
          ? _toDateTime(e, e.wakeTime)!
          .difference(_toDateTime(e, e.bedTime)!)
          : null;

      if (bedMin != null) {
        if (earliestBed == null || bedMin < earliestBed!) {
          earliestBed = bedMin;
          earliestBedDate = _entryDate(e);
        }
        if (latestBed == null || bedMin > latestBed!) {
          latestBed = bedMin;
          latestBedDate = _entryDate(e);
        }
      }

      if (wakeMin != null) {
        if (earliestWake == null || wakeMin < earliestWake!) {
          earliestWake = wakeMin;
          earliestWakeDate = _entryDate(e);
        }
        if (latestWake == null || wakeMin > latestWake!) {
          latestWake = wakeMin;
          latestWakeDate = _entryDate(e);
        }
      }

      if (durEntry != null) {
        if (shortest == null || durEntry < shortest!) {
          shortest = durEntry;
          shortestDate = _entryDate(e);
        }
        if (longest == null || durEntry > longest!) {
          longest = durEntry;
          longestDate = _entryDate(e);
        }
      }
    }

    String dateFmt(DateTime? d) =>
        d == null ? '' : DateFormat('dd.MM').format(d);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Средняя длительность сна: ${_formatDuration(dur)}'),
          const SizedBox(height: 12),
          Text('Среднее время подъёма: $wake'),
          const SizedBox(height: 12),
          Text('Среднее время отбоя: $bed'),
          const SizedBox(height: 12),
          Text('Самое раннее время отбоя: '
              '${earliestBed != null ? _fmtTime(earliestBed!) + ' — ' + dateFmt(earliestBedDate) : '-'}'),
          const SizedBox(height: 12),
          Text('Самое позднее время отбоя: '
              '${latestBed != null ? _fmtTime(latestBed!) + ' — ' + dateFmt(latestBedDate) : '-'}'),
          const SizedBox(height: 12),
          Text('Самое раннее время подъёма: '
              '${earliestWake != null ? _fmtTime(earliestWake!) + ' — ' + dateFmt(earliestWakeDate) : '-'}'),
          const SizedBox(height: 12),
          Text('Самое позднее время подъёма: '
              '${latestWake != null ? _fmtTime(latestWake!) + ' — ' + dateFmt(latestWakeDate) : '-'}'),
          const SizedBox(height: 12),
          Text('Самый короткий сон: '
              '${shortest != null ? _formatDuration(shortest!) + ' — ' + dateFmt(shortestDate) : '-'}'),
          const SizedBox(height: 12),
          Text('Самый длинный сон: '
              '${longest != null ? _formatDuration(longest!) + ' — ' + dateFmt(longestDate) : '-'}'),
        ],
      ),
    );
  }

  // eventsMap: date -> sleep duration in minutes
  Widget _buildCalendarTab(Map<DateTime, int> eventsMap) {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }
    final dates = eventsMap.keys.toList()..sort();
    final first = dates.first;
    final last = dates.last;
    return TableCalendar<int>(
      firstDay: first,
      lastDay: last,
      focusedDay: _focusedDay,
      onPageChanged: (d) => setState(() => _focusedDay = d),
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return eventsMap[key] != null ? [eventsMap[key]!] : [];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (ctx, day, events) {
          if (events.isEmpty) return const SizedBox();
          final v = events.first as int; // minutes
          final hours = v / 60;
          Color bg;
          if (hours <= 3) bg = Colors.red.shade200;
          else if (hours <= 6) bg = Colors.orange.shade300;
          else if (hours <= 8) bg = Colors.lightGreen.shade400;
          else bg = Colors.green.shade600;
          return Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text('${hours.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black)),
            ),
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        final key = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        final v = eventsMap[key];
        if (v == null) return;
        final msg = '${DateFormat('dd.MM').format(selectedDay)} '
            '— ${_formatDuration(Duration(minutes: v))}';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MyApp.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth - 32 - _dayWidth -
        _leftSpacing - _betweenSpacing - _rightSpacing;
    final hourWidth = width / 22;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер сна'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Трекер'),
            Tab(text: 'Статистика'),
            Tab(text: 'Календарь'),
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('7 дней'),
                  selected: _period == _Period.week,
                  onSelected: (_) {
                    setState(() => _period = _Period.week);
                    _applyPeriod();
                  },
                ),
                ChoiceChip(
                  label: const Text('30 дней'),
                  selected: _period == _Period.month,
                  onSelected: (_) {
                    setState(() => _period = _Period.month);
                    _applyPeriod();
                  },
                ),
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: _period == _Period.week
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                children: [
                  _buildTrackerTab(width, hourWidth),
                  _buildStatsTab(),
                  _buildCalendarTab({
                    for (final e in _entries)
                      _entryDate(e):
                      _toDateTime(e, e.wakeTime) == null ||
                          _toDateTime(e, e.bedTime) == null
                          ? 0
                          : (_toDateTime(e, e.wakeTime)!
                          .difference(_toDateTime(e, e.bedTime)!)
                          .inMinutes)
                          .clamp(0, 24 * 60)
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}