import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import '../../services/telegram_service.dart';
import 'entry_detail_screen.dart';
import 'export_screen.dart';
import 'import_screen.dart';
import 'analytics/analytics_menu_screen.dart';

enum EntriesMenu {
  export,
  importEntries,
  deleteAll,
  sendAll,
  analytics,
  sortRatingAsc,
  sortRatingDesc,
  resetSort,
  toggleTheme
}

enum SortMode { dateDesc, ratingAsc, ratingDesc }

class EntriesScreen extends StatefulWidget {
  static const routeName = '/entries';
  const EntriesScreen({Key? key}) : super(key: key);

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  DateTime? _fromDate, _toDate;
  int? _minRating;
  String? _searchText;
  SortMode _sortMode = SortMode.dateDesc;

  List<EntryData> _entries = [];
  late final Connectivity _connectivity;
  late final StreamSubscription<ConnectivityResult> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) {
      setState(() {}); // обновляем иконки “отправить”
    });
    _loadEntries();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  /// Загружает и фильтрует, затем применяет сортировку в зависимости от [_sortMode].
  Future<void> _loadEntries() async {
    // 1) Фильтр по рейтингу и тексту на уровне БД
    final raw = await LocalDb.fetchFiltered(
      minRating: _minRating,
      search: _searchText,
    );

    // 2) Фильтр по дате записи
    final filtered = raw.where((e) {
      final parts = e.date.split('-');
      if (parts.length != 3) return false;
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d == null || m == null || y == null) return false;
      final dt = DateTime(y, m, d);
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate   != null && dt.isAfter(_toDate!))   return false;
      return true;
    }).toList();

    // 3) По умолчанию сортируем по дате DESC
    filtered.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    // 4) Если выбран режим сортировки по рейтингу — применяем его
    if (_sortMode == SortMode.ratingAsc) {
      filtered.sort((a, b) => int.parse(a.rating).compareTo(int.parse(b.rating)));
    } else if (_sortMode == SortMode.ratingDesc) {
      filtered.sort((a, b) => int.parse(b.rating).compareTo(int.parse(a.rating)));
    }

    setState(() {
      _entries = filtered;
    });
  }

  Future<void> _openFilterSheet() async {
    DateTime? tmpFrom   = _fromDate;
    DateTime? tmpTo     = _toDate;
    int?     tmpMin     = _minRating;
    String?  tmpSearch  = _searchText;
    final    ctrl       = TextEditingController(text: tmpSearch);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx2).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateTile('Дата от', tmpFrom, (d) => setModal(() => tmpFrom = d)),
              _DateTile('Дата до', tmpTo,   (d) => setModal(() => tmpTo   = d)),
              ListTile(
                title: const Text('Точный рейтинг'),
                trailing: DropdownButton<int>(
                  value: tmpMin,
                  hint: const Text('Любой'),
                  items: List.generate(11,
                    (i) => DropdownMenuItem(value: i, child: Text('$i'))
                  ),
                  onChanged: (v) => setModal(() => tmpMin = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по тексту',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setModal(() => tmpSearch = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setModal(() {
                        tmpFrom = tmpTo = null;
                        tmpMin  = null;
                        tmpSearch = null;
                        ctrl.clear();
                      });
                    },
                    child: const Text('Сбросить'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fromDate   = tmpFrom;
                        _toDate     = tmpTo;
                        _minRating  = tmpMin;
                        _searchText = tmpSearch;
                      });
                      Navigator.pop(ctx2);
                    },
                    child: const Text('Применить'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    await _loadEntries();
  }

  Future<void> _tryResend(EntryData e) async {
    final ok = await TelegramService.sendEntry(e);
    if (ok) {
      e.needsSync = false;
      await LocalDb.saveOrUpdate(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Отправлено!')));
      setState(() {});
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Не удалось отправить')));
    }
  }

  Future<void> _editSendStatus(EntryData e) async {
    bool isSent = !e.needsSync;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool val = isSent;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Статус отправки'),
            content: CheckboxListTile(
              title: const Text('Отправлено'),
              value: val,
              onChanged: (v) => setState(() => val = v ?? false),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, val),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      e.needsSync = !result;
      await LocalDb.saveOrUpdate(e);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('📖 Мои записи', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Фильтры',
            onPressed: _openFilterSheet,
          ),
          PopupMenuButton<EntriesMenu>(
            onSelected: (item) async {
              switch (item) {
                case EntriesMenu.export:
                  Navigator.pushNamed(ctx, ExportScreen.routeName);
                  break;
                case EntriesMenu.importEntries:
                  await Navigator.pushNamed(ctx, ImportScreen.routeName);
                  await _loadEntries();
                  break;
                case EntriesMenu.analytics:
                  Navigator.pushNamed(ctx, AnalyticsMenuScreen.routeName);
                  break;
                case EntriesMenu.deleteAll:
                  await _confirmDeleteAll();
                  break;
                case EntriesMenu.sendAll:
                  await _sendAllChrono();
                  break;
                case EntriesMenu.sortRatingAsc:
                  _sortMode = SortMode.ratingAsc;
                  await _loadEntries();
                  break;
                case EntriesMenu.sortRatingDesc:
                  _sortMode = SortMode.ratingDesc;
                  await _loadEntries();
                  break;
                case EntriesMenu.resetSort:
                  _sortMode = SortMode.dateDesc;
                  await _loadEntries();
                  break;
                case EntriesMenu.toggleTheme:
                  appState.toggleTheme(!appState.isDark);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: EntriesMenu.export,
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Экспорт'),
                ),
              ),
              const PopupMenuItem(
                value: EntriesMenu.importEntries,
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Импорт записей'),
                ),
              ),
              const PopupMenuItem(
                value: EntriesMenu.analytics,
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Аналитика'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: EntriesMenu.sortRatingAsc,
                child: Text('Сортировать оценку ↑'),
              ),
              const PopupMenuItem(
                value: EntriesMenu.sortRatingDesc,
                child: Text('Сортировать оценку ↓'),
              ),
              const PopupMenuItem(
                value: EntriesMenu.resetSort,
                child: Text('Сбросить сортировку'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: EntriesMenu.deleteAll,
                child: ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Очистить все записи'),
                ),
              ),
              const PopupMenuItem(
                value: EntriesMenu.sendAll,
                child: ListTile(
                  leading: Icon(Icons.send),
                  title: Text('Отправить все по порядку'),
                ),
              ),
              PopupMenuItem(
                value: EntriesMenu.toggleTheme,
                child: ListTile(
                  leading: Icon(appState.isDark
                      ? Icons.sunny
                      : Icons.nightlight_round),
                  title: Text(appState.isDark
                      ? 'Светлая тема'
                      : 'Тёмная тема'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _entries.isEmpty
          ? const Center(child: Text('Записей нет'))
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (ctx, i) {
                final e = _entries[i];
                return Dismissible(
                  key: ValueKey(e.localId),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (dir) async {
                    if (dir == DismissDirection.startToEnd) {
                      await _tryResend(e);
                      return false;
                    } else {
                      final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (dctx) => AlertDialog(
                              title: const Text('Удалить запись?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(dctx, false),
                                    child: const Text('Нет')),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(dctx, true),
                                    child: const Text('Да')),
                              ],
                            ),
                          ) ??
                          false;
                      if (ok) await LocalDb.delete(e.localId!);
                      return ok;
                    }
                  },
                  onDismissed: (dir) {
                    setState(() {});
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text(dir == DismissDirection.endToStart
                              ? 'Запись удалена'
                              : 'Отправка выполнена')),
                    );
                  },
                  child: ListTile(
                    leading: e.needsSync
                        ? const Icon(Icons.cloud_upload,
                            color: Colors.amber)
                        : const Icon(Icons.event_note_outlined,
                            color: Colors.grey),
                    title: Text(e.date),
                    subtitle: e.needsSync
                        ? const Text('Не отправлено')
                        : null,
                    onLongPress: () => _editSendStatus(e),
                    trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                    onTap: () async {
                      await Navigator.pushNamed(
                        ctx,
                        EntryDetailScreen.routeName,
                        arguments: e,
                      );
                      await _loadEntries(); // сортировка сейчас сохранится
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Очистить всю базу?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Нет')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Да')),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await LocalDb.clearAll();
      await _loadEntries();
    }
  }

  Future<void> _sendAllChrono() async {
    final sorted = [..._entries]
      ..sort(
          (a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
    for (final e in sorted) {
      await TelegramService.sendEntry(e);
    }
    await _loadEntries();
  }

  DateTime _parseDate(String date) {
    final parts = date.split('-');
    final d = int.tryParse(parts[0]) ?? 1;
    final m = int.tryParse(parts[1]) ?? 1;
    final y = int.tryParse(parts[2]) ?? DateTime.now().year;
    return DateTime(y, m, d);
  }
}

class _DateTile extends StatelessWidget {
  final String title;
  final DateTime? value;
  final void Function(DateTime?) onPick;
  const _DateTile(this.title, this.value, this.onPick, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value == null
            ? '—'
            : '${value!.day.toString().padLeft(2, '0')}.'
                '${value!.month.toString().padLeft(2, '0')}.'
                '${value!.year}',
      ),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (d != null) onPick(d);
      },
    );
  }
}
