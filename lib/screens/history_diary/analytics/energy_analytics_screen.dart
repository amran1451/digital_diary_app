import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_heatmap_calendar/simple_heatmap_calendar.dart';
import '../../../models/entry_data.dart';
import '../../../services/local_db.dart';
import '../../../main.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final all = await LocalDb.fetchAll();
    all.sort((a,b)=>a.createdAt.compareTo(b.createdAt));
    setState(()=>_all=all);
    _apply();
  }

  void _apply(){
    setState((){
      switch(_period){
        case _Period.week:
          _ent = _all.length>7 ? _all.sublist(_all.length-7) : List.from(_all);
          break;
        case _Period.month:
          _ent = _all.length>30? _all.sublist(_all.length-30):List.from(_all);
          break;
        case _Period.all:
          _ent = List.from(_all);
          break;
      }
    });
  }

  double get _min => _ent.isEmpty?0:_ent.map((e)=>double.tryParse(e.energy)??0).reduce(min);
  double get _max => _ent.isEmpty?0:_ent.map((e)=>double.tryParse(e.energy)??0).reduce(max);
  double get _avg {
    if(_ent.isEmpty) return 0;
    final s = _ent.map((e)=>double.tryParse(e.energy)??0).reduce((a,b)=>a+b);
    return s/_ent.length;
  }
  double get _sd {
    if(_ent.length<2) return 0;
    final m=_avg;
    final vs = _ent.map((e)=>pow((double.tryParse(e.energy)??0)-m,2)).reduce((a,b)=>a+b);
    return sqrt(vs/(_ent.length-1));
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
        bottom: TabBar(controller:_tabController,tabs:const[
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
      dates.add(e.createdAt);
      spots.add(FlSpot(i.toDouble(), double.tryParse(e.energy)??0));
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
    return SingleChildScrollView(
      child: DataTable(columns: const[
        DataColumn(label: Text('Дата')),
        DataColumn(label: Text('Энергия')),
      ], rows: _ent.map((e){
        return DataRow(cells:[
          DataCell(Text(DateFormat('dd.MM.yyyy').format(e.createdAt))),
          DataCell(Text(e.energy)),
        ]);
      }).toList()),
    );
  }

  Widget _buildCalendar(){
    if(_ent.isEmpty) return const Center(child:Text('Нет данных'));
    final map=<DateTime,int>{ for(var e in _ent) e.createdAt: int.tryParse(e.energy)??0 };
    final first=_ent.first.createdAt;
    final last=_ent.last.createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:16),
      child: HeatmapCalendar<num>(
        startDate:first,
        endedDate:last,
        colorMap:{
          1: Colors.red.shade200,
          4: Colors.orange.shade300,
          7: Colors.lightGreen.shade400,
          9: Colors.green.shade600,
        },
        selectedMap: map,
        cellSize: const Size.square(16),
        colorTipCellSize: const Size.square(12),
      ),
    );
  }
}
