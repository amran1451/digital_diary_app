import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';
import '../../../utils/parse_utils.dart';

enum _Period { week, month, all }

class EnergyAnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics/energy';
  const EnergyAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<EnergyAnalyticsScreen> createState() => _EnergyAnalyticsScreenState();
}

class _EnergyAnalyticsScreenState extends State<EnergyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntryData> _all = [], _ent = [];
  _Period _period = _Period.week;
  DateTime _calendarFocused = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a, b) => _entryDate(a).compareTo(_entryDate(b)));
    setState(() => _all = all);
    _apply();
  }

  void _apply(){
    setState((){
      switch(_period){
        case _Period.week:
          final cutoff = DateTime.now().subtract(const Duration(days: 7));
          final start = DateTime(cutoff.year, cutoff.month, cutoff.day);
          _ent = _all
              .where((e) =>
              _entryDate(e).isAfter(start) ||
              _entryDate(e).isAtSameMomentAs(start))
              .toList();
          break;
        case _Period.month:
          final cutoff = DateTime.now().subtract(const Duration(days: 30));
          final start = DateTime(cutoff.year, cutoff.month, cutoff.day);
          _ent = _all
              .where((e) =>
              _entryDate(e).isAfter(start) ||
              _entryDate(e).isAtSameMomentAs(start))
              .toList();
          break;
        case _Period.all:
          _ent = List.from(_all);
          break;
      }
      if(_ent.isNotEmpty){
        _calendarFocused = _entryDate(_ent.last);
      } else {
        _calendarFocused = DateTime.now();
      }
    });
  }

  double get _min =>
      _ent.isEmpty ? 0 : _ent.map((e) => ParseUtils.parseDouble(e.energy)).reduce(min);
  double get _max =>
      _ent.isEmpty ? 0 : _ent.map((e) => ParseUtils.parseDouble(e.energy)).reduce(max);
  double get _avg {
    if(_ent.isEmpty) return 0;
    final s = _ent.map((e)=>double.tryParse(e.energy)??0).reduce((a,b)=>a+b);
    return s/_ent.length;
  }
  double get _sd {
    if(_ent.length<2) return 0;
    final m=_avg;
    final vs =
    _ent.map((e) => pow((ParseUtils.parseDouble(e.energy) - m), 2)).reduce((a, b) => a + b);
    return sqrt(vs/(_ent.length-1));
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

  Future<void> _share() async {
    final buf=StringBuffer()
      ..writeln('Аналитика энергии за ${_period==_Period.week?"7 дней":_period==_Period.month?"30 дней":"весь период"}')
      ..writeln('Среднее: ${_avg.toStringAsFixed(1)}')
      ..writeln('Мин: ${_min.toStringAsFixed(1)}, Макс: ${_max.toStringAsFixed(1)}')
      ..writeln('Дней: ${_ent.length}, SD: ${_sd.toStringAsFixed(1)}');
    await Share.share(buf.toString(),subject:'Аналитика энергии');
  }

  @override
  void dispose(){
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c){
    final app = MyApp.of(c);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика энергии'),
        bottom: TabBar(
            controller:_tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white,
            tabs:const[
          Tab(text:'График'),Tab(text:'Таблица'),Tab(text:'Календарь'),
        ]),
        actions:[
          IconButton(
            icon: Icon(app.isDark?Icons.sunny:Icons.nightlight_round),
            onPressed: ()=>app.toggleTheme(!app.isDark),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical:12,horizontal:16),
        child: Column(children:[
          Row(mainAxisAlignment: MainAxisAlignment.center, children:[
            ChoiceChip(
              label: const Text('7 дн'),
              selected: _period==_Period.week,
              onSelected: (_){ setState(()=>_period=_Period.week); _apply(); },
            ),
            const SizedBox(width:8),
            ChoiceChip(
              label: const Text('30 дн'),
              selected: _period==_Period.month,
              onSelected: (_){ setState(()=>_period=_Period.month); _apply(); },
            ),
            const SizedBox(width:8),
            ChoiceChip(
              label: const Text('Весь'),
              selected: _period==_Period.all,
              onSelected: (_){ setState(()=>_period=_Period.all); _apply(); },
            ),
          ]),
          const SizedBox(height:8),
          const Text(
            'Период считается от сегодняшней даты. Полные данные в разделе "По месяцам".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize:12,color:Colors.grey),
          ),
          const SizedBox(height:12),
          Expanded(
            child: TabBarView(controller:_tabController, physics: _period==_Period.all?null: const NeverScrollableScrollPhysics(), children:[
              _buildChart(c),
              _buildTable(),
              _buildCalendar(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildChart(BuildContext c){
    if(_ent.isEmpty) return const Center(child: Text('Нет данных'));
    final spots=<FlSpot>[];
    final dates=<DateTime>[];
    for(int i=0;i<_ent.length;i++){
      final e=_ent[i];
      dates.add(_entryDate(e));
      spots.add(FlSpot(i.toDouble(), ParseUtils.parseDouble(e.energy)));
    }
    final today=DateTime.now();
    final wi=max(_ent.length*40.0, MediaQuery.of(c).size.width);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: wi, height:300,
        child: LineChart(LineChartData(
          minY:0, maxY:10.2,
          gridData: FlGridData(
            show:true,
            horizontalInterval:1,
            getDrawingHorizontalLine:(v)=>FlLine(color:Colors.grey.withOpacity(.3),strokeWidth:0.5),
          ),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations:[
              HorizontalRangeAnnotation(y1:0,y2:3,color:Colors.red.withOpacity(.1)),
              HorizontalRangeAnnotation(y1:3,y2:6,color:Colors.orange.withOpacity(.1)),
              HorizontalRangeAnnotation(y1:6,y2:8,color:Colors.lightGreen.withOpacity(.1)),
              HorizontalRangeAnnotation(y1:8,y2:10.2,color:Colors.green.withOpacity(.1)),
            ],
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles:true,
              interval: (_ent.length/7).ceilToDouble().clamp(1, double.infinity),
              reservedSize:30,
              getTitlesWidget:(v,_) {
                final i=v.toInt();
                if(i<0||i>=dates.length) return const SizedBox();
                return Transform.rotate(
                  angle:-.5,
                  child: Text(DateFormat('dd.MM').format(dates[i]), style: const TextStyle(fontSize:10)),
                );
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles:true, interval:1, reservedSize:28,
              getTitlesWidget:(v,_){
                if(v>10) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right:6),
                  child: Text(v.toInt().toString(), style: const TextStyle(fontSize:10)),
                );
              },
            )),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles:false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles:false)),
          ),
          lineBarsData:[
            LineChartBarData(
              spots: spots,
              isCurved:true,
              color: Theme.of(c).colorScheme.primary,
              barWidth:2.5,
              dotData: FlDotData(show:true),
            )
          ],
        )),
      ),
    );
  }

  Widget _buildTable(){
    final grouped = <DateTime, List<double>>{};
    for (var e in _ent) {
      final k = _entryDate(e);
      (grouped[k] ??= []).add(ParseUtils.parseDouble(e.energy));
    }
    final rows = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Дата')),
          DataColumn(label: Text('Энергия')),
        ],
        rows: rows.map((e) {
          final avg = e.value.reduce((a, b) => a + b) / e.value.length;
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd.MM.yyyy').format(e.key))),
            DataCell(Text(avg.toStringAsFixed(1))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildCalendar() {
    if (_ent.isEmpty) return const Center(child: Text('Нет данных'));

    // Собираем значения энергии по дням без учёта времени
    final raw = <DateTime, List<double>>{};
    for (var e in _ent) {
      final key = _entryDate(e);
      (raw[key] ??= []).add(ParseUtils.parseDouble(e.energy));
    }

    // Диапазон отображаемых дат в зависимости от выбранного периода
    late DateTime first;
    late DateTime last;
    if (_period == _Period.all) {
      final allKeys = raw.keys.toList()..sort();
      if (allKeys.isNotEmpty) {
        first = allKeys.first;
        last = allKeys.last;
      } else {
        final now = DateTime.now();
        first = DateTime(now.year, now.month, now.day);
        last = first;
      }
    } else {
      final now = DateTime.now();
      last = DateTime(now.year, now.month, now.day);
      first = _period == _Period.week
          ? last.subtract(const Duration(days: 7))
          : last.subtract(const Duration(days: 30));
    }

    // Заполняем значения энергии только для дат с данными
    final data = <DateTime, double>{};
    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      final list = raw[d];
      if (list != null && list.isNotEmpty) {
        data[d] = list.reduce((a, b) => a + b) / list.length;
      }
    }

    Color _colorFor(double v) {
      if (v <= 3) return Colors.red.shade600;
      if (v <= 6) return Colors.orange.shade300;
      if (v <= 8) return Colors.lightGreen.shade400;
      return Colors.green.shade600;
    }

    return TableCalendar(
      firstDay: first,
      lastDay: last,
      focusedDay: _calendarFocused.isBefore(first) || _calendarFocused.isAfter(last)
          ? last
          : _calendarFocused,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: const CalendarStyle(outsideDaysVisible: true),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (ctx, date, _) {
          final key = DateTime(date.year, date.month, date.day);
          final v = data[key];
          if (v == null) return null;
          return Container(
            decoration: BoxDecoration(
              color: _colorFor(v),
              borderRadius: BorderRadius.circular(4),
            ),
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Text('${date.day}', style: const TextStyle(fontSize: 12)),
          );
        },
        todayBuilder: (ctx, date, _) {
          final key = DateTime(date.year, date.month, date.day);
          final v = data[key];
          if (v == null) return null;
          return Container(
            decoration: BoxDecoration(
              color: _colorFor(v),
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Text('${date.day}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          );
        },
        outsideBuilder: (ctx, date, _) {
          final key = DateTime(date.year, date.month, date.day);
          final v = data[key];
          if (v == null) return null;
          return Container(
            decoration: BoxDecoration(
              color: _colorFor(v),
              borderRadius: BorderRadius.circular(4),
            ),
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Text('${date.day}',
                style:
                const TextStyle(fontSize: 12, color: Colors.black54)),
          );
        },
      ),
      onDaySelected: (date, _) {
        final ds = DateFormat('dd.MM.yyyy').format(date);
        final key = DateTime(date.year, date.month, date.day);
        final v = data[key];
        final msg =
        v == null ? 'Дата: $ds — нет данных' : 'Дата: $ds — энергия: $v';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      onPageChanged: (d) => setState(() => _calendarFocused = d),
    );
  }
}
