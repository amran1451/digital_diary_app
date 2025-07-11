import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
// `ScrollDirection` is defined in the rendering library. Importing it
// explicitly avoids "isn't a type" errors during compilation.
import 'package:flutter/rendering.dart';

import '../../main.dart';
import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import '../../services/telegram_service.dart';
import '../../theme/dark_diary_theme.dart';
import 'entry_detail_screen_new.dart';
import '../history_diary/export_screen.dart';
import '../history_diary/import_screen.dart';
import '../history_diary/analytics/analytics_menu_screen.dart';
import '../../utils/rating_emoji.dart';

enum MyRecordsMenu {
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

class MyRecordsScreen extends StatefulWidget {
  static const routeName = '/my_records';
  const MyRecordsScreen({Key? key}) : super(key: key);

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  DateTime? _fromDate, _toDate;
  int? _minRating;
  String? _searchText;
  SortMode _sortMode = SortMode.dateDesc;

  List<EntryData> _entries = [];
  late final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  final ScrollController _scrollCtrl = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) {
      setState(() {}); // обновляем иконки “отправить”
    });
    _scrollCtrl.addListener(() {
      final ScrollDirection dir =
          _scrollCtrl.position.userScrollDirection;
      if (dir == ScrollDirection.reverse && _showFab) {
        setState(() => _showFab = false);
      } else if (dir == ScrollDirection.forward && !_showFab) {
        setState(() => _showFab = true);
      }
    });
    _loadEntries();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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
            bottom: MediaQuery.of(ctx2).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
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
    bool bulkAction = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool val = isSent;
        final anyUnsent = _entries.any((el) => el.needsSync);
        final anySent = _entries.any((el) => !el.needsSync);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Статус отправки'),
            content: CheckboxListTile(
              title: const Text('Отправлено'),
              value: val,
              onChanged: (v) => setState(() => val = v ?? false),
            ),
            actions: [
              if (anyUnsent)
                TextButton(
                  onPressed: () async {
                    bulkAction = true;
                    await LocalDb.markAllSynced();
                    Navigator.pop(ctx, val);
                  },
                  child: const Text('Отметить все как отправленные'),
                ),
              if (anySent)
                TextButton(
                  onPressed: () async {
                    bulkAction = true;
                    await LocalDb.markAllUnsent();
                    Navigator.pop(ctx, val);
                  },
                  child: const Text('Снять отметку у всех'),
                ),
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
    if (bulkAction) {
      await _loadEntries();
      return;
    }
    if (result != null) {
      e.needsSync = !result;
      await LocalDb.saveOrUpdate(e);
      if (mounted) setState(() {});
    }
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[];
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    if (_fromDate != null) {
      chips.add(InputChip(
        label: Text('от ${fmt(_fromDate!)}'),
        onDeleted: () async {
          setState(() => _fromDate = null);
          await _loadEntries();
        },
      ));
    }
    if (_toDate != null) {
      chips.add(InputChip(
        label: Text('до ${fmt(_toDate!)}'),
        onDeleted: () async {
          setState(() => _toDate = null);
          await _loadEntries();
        },
      ));
    }
    if (_minRating != null) {
      chips.add(InputChip(
        label: Text('рейтинг $_minRating'),
        onDeleted: () async {
          setState(() => _minRating = null);
          await _loadEntries();
        },
      ));
    }
    return chips.isEmpty
        ? const SizedBox.shrink()
        : Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, children: chips),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);

    final theme = DarkDiaryTheme.theme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
          title: const Text('Мои записи'),
          actions: [
            PopupMenuButton<MyRecordsMenu>(
              onSelected: (item) async {
                switch (item) {
                  case MyRecordsMenu.export:
                    Navigator.pushNamed(ctx, ExportScreen.routeName);
                    break;
                  case MyRecordsMenu.importEntries:
                    await Navigator.pushNamed(ctx, ImportScreen.routeName);
                    await _loadEntries();
                    break;
                  case MyRecordsMenu.analytics:
                    Navigator.pushNamed(ctx, AnalyticsMenuScreen.routeName);
                    break;
                  case MyRecordsMenu.deleteAll:
                    await _confirmDeleteAll();
                    break;
                  case MyRecordsMenu.sendAll:
                    await _sendAllChrono();
                    break;
                  case MyRecordsMenu.sortRatingAsc:
                    _sortMode = SortMode.ratingAsc;
                    await _loadEntries();
                    break;
                  case MyRecordsMenu.sortRatingDesc:
                    _sortMode = SortMode.ratingDesc;
                    await _loadEntries();
                    break;
                  case MyRecordsMenu.resetSort:
                    _sortMode = SortMode.dateDesc;
                    await _loadEntries();
                    break;
                  case MyRecordsMenu.toggleTheme:
                    appState.toggleTheme(!appState.isDark);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: MyRecordsMenu.export,
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Экспорт'),
                  ),
                ),
                const PopupMenuItem(
                  value: MyRecordsMenu.importEntries,
                  child: ListTile(
                    leading: Icon(Icons.file_download),
                    title: Text('Импорт записей'),
                  ),
                ),
                const PopupMenuItem(
                  value: MyRecordsMenu.analytics,
                  child: ListTile(
                    leading: Icon(Icons.analytics),
                    title: Text('Аналитика'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: MyRecordsMenu.sortRatingAsc,
                  child: Text('Сортировать оценку ↑'),
                ),
                const PopupMenuItem(
                  value: MyRecordsMenu.sortRatingDesc,
                  child: Text('Сортировать оценку ↓'),
                ),
                const PopupMenuItem(
                  value: MyRecordsMenu.resetSort,
                  child: Text('Сбросить сортировку'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: MyRecordsMenu.deleteAll,
                  child: ListTile(
                    leading: Icon(Icons.delete_forever),
                    title: Text('Очистить все записи'),
                  ),
                ),
                const PopupMenuItem(
                  value: MyRecordsMenu.sendAll,
                  child: ListTile(
                    leading: Icon(Icons.send),
                    title: Text('Отправить все по порядку'),
                  ),
                ),
                PopupMenuItem(
                  value: MyRecordsMenu.toggleTheme,
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
        body: Column(
            children: [
            _buildFilterChips(),
        Expanded(
          child: _entries.isEmpty
              ? const Center(child: Text('Записей нет'))
              : ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(8),
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
                  setState(() {
                    _entries.removeAt(i);
                  });
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        dir == DismissDirection.endToStart
                            ? 'Запись удалена'
                            : 'Отправка выполнена',
                      ),
                    ),
                  );
                },
                child: _RecordCard(
                  entry: e,
                  onTap: () async {
                    await Navigator.pushNamed(
                      ctx,
                      EntryDetailScreenNew.routeName,
                      arguments: e,
                    );
                    await _loadEntries();
                  },
                  onLongPress: () => _editSendStatus(e),
                ),
              );
            },
          ),
        ),
            ],
        ),
        floatingActionButton: _showFab
            ? FloatingActionButton.extended(
          onPressed: _openFilterSheet,
          icon: const Icon(Icons.filter_list),
          label: const Text('Фильтровать'),
        )
            : null,
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

String _emojiFromRating(int rating) {
  return ratingEmoji[rating] ?? '🤔';
}

class _RecordCard extends StatelessWidget {
  final EntryData entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RecordCard({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = int.tryParse(entry.rating) ?? 0;
    final emoji = _emojiFromRating(rating);
    final sent = !entry.needsSync;
    return Card(
      color: const Color(0xFF211C2A),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(entry.date, style: theme.textTheme.bodyLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DarkDiaryTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.rating,
                style: theme.textTheme.labelLarge!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              sent ? Icons.check_circle : Icons.schedule,
              color: sent ? Colors.green : Colors.amber,
              size: 16,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        subtitle:
        sent ? const Text('Отправлено') : const Text('Не отправлено'),
      ),
    );
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