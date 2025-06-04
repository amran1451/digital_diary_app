// lib/screens/sleep_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  static const double _dayWidth = 32;

  List<EntryData> _allEntries = [];
  List<EntryData> _entries = [];
  _Period _period = _Period.week;

  @override
  void initState() {
    super.initState();
    _loadEntries();
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

  void _showDetails(EntryData e) {
    final bed = _toDateTime(e, e.bedTime);
    final wake = _toDateTime(e, e.wakeTime);
    if (bed == null || wake == null) return;
    final dur = wake.difference(bed);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(DateFormat('dd.MM.yyyy').format(_entryDate(e))),
        content: Text(
          'Длительность: ${_formatDuration(dur)}\n'
              'Засыпание: ${e.bedTime}\n'
              'Пробуждение: ${e.wakeTime}\n'
              'Энергия: ${e.energy}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildAxis(double width, double hourWidth) {
    final labels = [
      for (int h = 18; h <= 22; h += 2) '$h',
      '0',
      for (int h = 2; h <= 16; h += 2) '$h',
    ];
    return Row(
      children: [
        const SizedBox(width: _dayWidth),
        SizedBox(
          width: width,
          height: 20,
          child: Row(
            children: [
              for (int i = 0; i < labels.length; i++)
                SizedBox(
                  width: hourWidth * 2,
                  child: Center(
                      child: Text(labels[i],
                          style: const TextStyle(fontSize: 10))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(EntryData e, double width, double hourWidth) {
    final bed = _toDateTime(e, e.bedTime);
    final wake = _toDateTime(e, e.wakeTime);
    final day = DateFormat('dd.MM').format(_entryDate(e));

    if (bed == null || wake == null || wake.isBefore(bed)) {
      return Row(
        children: [
          SizedBox(width: _dayWidth, child: Text(day)),
          SizedBox(
            width: width,
            height: 24,
            child:
            const Center(child: Text('не спал ☹️')),
          ),
        ],
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

    return Row(
      children: [
        SizedBox(width: _dayWidth, child: Text(day)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MyApp.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth - 32 - _dayWidth;
    final hourWidth = width / 22;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер сна'),
        centerTitle: true,
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
        ),
      ),
    );
  }
}