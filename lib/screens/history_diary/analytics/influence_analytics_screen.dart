import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';

// Emotion categories used in entry editing screen. Key contains emoji and name.
const Map<String, List<String>> _emotionCategories = {
  '😄 Радость': [
    'Воодушевление',
    'Восторг',
    'Интерес',
    'Радость',
    'Счастье',
    'Лёгкость',
    'Теплота',
    'Любовь',
    'Обожание',
  ],
  '😔 Грусть': [
    'Печаль',
    'Одиночество',
    'Уныние',
    'Потерянность',
    'Безысходность',
    'Ностальгия',
    'Тоска',
    'Экзистенциальная тоска',
    'Меланхолия',
  ],
  '😰 Тревога': [
    'Беспокойство',
    'Неуверенность',
    'Паника',
    'Напряжение',
    'Предвкушение негатива',
    'Тревога',
    'Растерянность',
    'Трепет',
  ],
  '😡 Злость': [
    'Раздражение',
    'Обида',
    'Зависть',
    'Агрессия',
    'Неприязнь',
    'Фрустрация',
    'Сопротивление',
  ],
  '😶 Оцепенение': [
    'Пустота',
    'Замерзание',
    'Онемение',
    'Тупик',
    'Хтонь',
  ],
  '🤍 Принятие': [
    'Спокойствие',
    'Устойчивость',
    'Принятие',
    'Доверие',
    'Резонанс',
  ],
  '💭 Сложные/смешанные': [
    'Вина',
    'Стыд',
    'Смущение',
    'Неловкость',
    'Амбивалентность',
    'Уязвимость',
    'Катарсис',
  ],
};

final Map<String, String> _emotionToCategory = (() {
  final map = <String, String>{};
  _emotionCategories.forEach((cat, list) {
    for (final emo in list) {
      map[emo] = cat;
    }
  });
  return map;
})();

class _ReasonStat {
  final String reason;
  final String emotion;
  final String category;
  int count = 0;
  double ratingSum = 0;
  _ReasonStat(this.reason, this.emotion, this.category);
  double get avgRating => count == 0 ? 0 : ratingSum / count;
}

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

  /// Aggregated statistics per reason-emotion pair
  final Map<String, _ReasonStat> _stats = {};
  final Set<String> _selectedReasons = <String>{};
  final Set<String> _selectedEmotions = <String>{};

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
    _stats.clear();
    final regex = RegExp(r'(.*?)\s*[—-]\s*(\([^)]*\)|[^,]+)(?:,|$)');
    for (final e in _entries) {
      final rating = double.tryParse(e.rating) ?? 0;
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
        final key = '$emo|$reason';
        final cat = _emotionToCategory[emo] ?? '';
        final stat = _stats.putIfAbsent(key, () => _ReasonStat(reason, emo, cat));
        stat.count += 1;
        stat.ratingSum += rating;
      }
    }
    _reasonCounts = counts;
    _emotions = emotions.toList()..sort();
  }


  Widget _buildReasonChart() {
    if (_stats.isEmpty) {
      return const Center(child: Text('Нет доступных данных для выбранного периода'));
    }
    final list = _stats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return ListView.separated(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        final emoji = s.category.isNotEmpty ? s.category.split(' ').first : '';
        return ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 20)),
          title: Text(s.reason),
          subtitle: Text('${s.emotion} • ${s.avgRating.toStringAsFixed(1)}'),
          trailing: Text(s.count.toString()),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }

  Widget _buildLineChart() {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет доступных данных для выбранного периода'));
    }
    final series = <String, Map<DateTime, int>>{};
    final regex = RegExp(r'(.*?)\s*[—-]\s*(\([^)]*\)|[^,]+)(?:,|$)');
    for (final e in _entries) {
      final date = _entryDate(e);
      for (final m in regex.allMatches(e.influence)) {
        final emo = m.group(1)!.trim();
        var reason = m.group(2)!.trim();
        if (reason.startsWith('(') && reason.endsWith(')')) {
          reason = reason.substring(1, reason.length - 1).trim();
        }
        if (_selectedEmotions.isNotEmpty && !_selectedEmotions.contains(emo)) continue;
        if (_selectedReasons.isNotEmpty && !_selectedReasons.contains(reason)) continue;
        final key = '$emo|$reason';
        final map = series.putIfAbsent(key, () => <DateTime, int>{});
        map[date] = (map[date] ?? 0) + 1;
      }
    }
    if (series.isEmpty) {
      return const Center(child: Text('Нет доступных данных для выбранного периода'));
    }
    final dates = series.values.expand((m) => m.keys).toSet().toList()..sort();
    final bars = <LineChartBarData>[];
    double maxVal = 0;
    final palette = Colors.primaries;
    var idx = 0;
    series.forEach((name, data) {
      final spots = <FlSpot>[];
      for (var i = 0; i < dates.length; i++) {
        final d = dates[i];
        final v = (data[d] ?? 0).toDouble();
        if (v > maxVal) maxVal = v;
        spots.add(FlSpot(i.toDouble(), v));
      }
      bars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 2,
        color: palette[idx % palette.length],
      ));
      idx++;
    });
    final labelStep = max(1, (dates.length / 10).ceil());
    return LineChart(
      LineChartData(
        maxY: maxVal + 1,
        minY: 0,
        lineBarsData: bars,
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
                if (v > maxVal + 1) return const SizedBox();
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

  Widget _dynamicTab() {
    if (_stats.isEmpty) {
      return const Center(child: Text('Нет доступных данных для выбранного периода'));
    }
    final reasons = _reasonCounts.keys.toList()..sort();
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: reasons.map((r) {
                    final selected = _selectedReasons.contains(r);
                    return FilterChip(
                      label: Text(r),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            if (_selectedReasons.length < 3) _selectedReasons.add(r);
                          } else {
                            _selectedReasons.remove(r);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _emotions.map((e) {
                    final selected = _selectedEmotions.contains(e);
                    return FilterChip(
                      label: Text(e),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            if (_selectedEmotions.length < 3) _selectedEmotions.add(e);
                          } else {
                            _selectedEmotions.remove(e);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: max(constraints.maxHeight - 120, 200),
                  child: _buildLineChart(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildTable() {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет доступных данных для выбранного периода'));
    }
    final rows = <DataRow>[];
    final regex = RegExp(r'(.*?)\s*[—-]\s*(\([^)]*\)|[^,]+)(?:,|$)');
    for (final e in _entries) {
      for (final m in regex.allMatches(e.influence)) {
        final emo = m.group(1)!.trim();
        var reason = m.group(2)!.trim();
        if (reason.startsWith('(') && reason.endsWith(')')) {
          reason = reason.substring(1, reason.length - 1).trim();
        }
        final cat = _emotionToCategory[emo] ?? '';
        rows.add(DataRow(cells: [
          DataCell(Text(e.date)),
          DataCell(Text(emo)),
          DataCell(Text(cat)),
          DataCell(Text(reason)),
          DataCell(Text(e.rating)),
        ]));
      }
    }
    if (rows.isEmpty) {
      return const Center(child: Text('Нет доступных данных для выбранного периода'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Дата')),
          DataColumn(label: Text('Эмоция')),
          DataColumn(label: Text('Категория')),
          DataColumn(label: Text('Причина')),
          DataColumn(label: Text('Оценка')),
        ],
        rows: rows,
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
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReasonChart(),
                  _dynamicTab(),
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