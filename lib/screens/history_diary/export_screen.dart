import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import '../../services/pdf_service.dart';
import '../../services/csv_service.dart';
import '../../main.dart';

class ExportScreen extends StatefulWidget {
  static const routeName = '/export';
  const ExportScreen({Key? key}) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

enum _PeriodPreset {
  last7,
  last30,
  thisMonth,
  prevMonth,
  allTime,
  manual,
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  _PeriodPreset _preset = _PeriodPreset.allTime;

  void _applyPreset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_preset) {
      case _PeriodPreset.last7:
        _fromDate = today.subtract(const Duration(days: 6));
        _toDate = today;
        break;
      case _PeriodPreset.last30:
        _fromDate = today.subtract(const Duration(days: 29));
        _toDate = today;
        break;
      case _PeriodPreset.thisMonth:
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month + 1, 0);
        break;
      case _PeriodPreset.prevMonth:
        final firstCurrent = DateTime(now.year, now.month, 1);
        final lastPrev = firstCurrent.subtract(const Duration(days: 1));
        _fromDate = DateTime(lastPrev.year, lastPrev.month, 1);
        _toDate = DateTime(lastPrev.year, lastPrev.month + 1, 0);
        break;
      case _PeriodPreset.allTime:
        _fromDate = null;
        _toDate = null;
        break;
      case _PeriodPreset.manual:
      // keep current manual values
        break;
    }
  }


  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  Future<Directory?> _selectDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите папку для сохранения',
    );
    if (path == null) return null;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _exportPdf() async {
    // Получаем записи из локальной БД c учётом выбранного диапазона
    final filtered = await LocalDb.fetchFiltered(
      from: _fromDate,
      to: _toDate,
    );

    final pdfBytes = await PdfService.generatePdf(filtered);

    // Формируем читаемое имя файла
    String format(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    late final String fileName;
    if (_fromDate != null && _toDate != null) {
      fileName = 'Выгрузка записей за ${format(_fromDate!)} - ${format(_toDate!)}.pdf';
    } else if (_fromDate != null) {
      fileName = 'Выгрузка записей с ${format(_fromDate!)}.pdf';
    } else if (_toDate != null) {
      fileName = 'Выгрузка записей до ${format(_toDate!)}.pdf';
    } else {
      fileName = 'Выгрузка всех записей.pdf';
    }

    // Шарим или печатаем PDF
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  Future<void> _exportCsv() async {
    if (!await PermissionService.requestStoragePermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступа к памяти устройства')),
        );
      }
      return;
    }
    final filtered = await LocalDb.fetchFiltered(
      from: _fromDate,
      to: _toDate,
    );
    final csvData = CsvService.generateCsv(filtered);

    String format(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    late final String fileName;
    if (_fromDate != null && _toDate != null) {
      fileName = 'Выгрузка записей за ${format(_fromDate!)} - ${format(_toDate!)}.csv';
    } else if (_fromDate != null) {
      fileName = 'Выгрузка записей с ${format(_fromDate!)}.csv';
    } else if (_toDate != null) {
      fileName = 'Выгрузка записей до ${format(_toDate!)}.csv';
    } else {
      fileName = 'Выгрузка всех записей.csv';
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvData, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  }

  Future<void> _savePdf() async {
    if (!await PermissionService.requestStoragePermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступа к памяти устройства')),
        );
      }
      return;
    }
    final filtered = await LocalDb.fetchFiltered(
      from: _fromDate,
      to: _toDate,
    );

    final pdfBytes = await PdfService.generatePdf(filtered);

    String format(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    late final String fileName;
    if (_fromDate != null && _toDate != null) {
      fileName = 'Выгрузка записей за ${format(_fromDate!)} - ${format(_toDate!)}.pdf';
    } else if (_fromDate != null) {
      fileName = 'Выгрузка записей с ${format(_fromDate!)}.pdf';
    } else if (_toDate != null) {
      fileName = 'Выгрузка записей до ${format(_toDate!)}.pdf';
    } else {
      fileName = 'Выгрузка всех записей.pdf';
    }

    Directory? dir = await _selectDirectory();
    if (dir == null) {
      if (Platform.isAndroid) {
        final dirs =
        await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) dir = dirs.first;
      } else {
        dir = await getDownloadsDirectory();
      }
    }
    dir ??= await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/$fileName');
    try {
      await file.writeAsBytes(pdfBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить файл: $e')),
      );
    }
  }

  Future<void> _saveCsv() async {
    if (!await PermissionService.requestStoragePermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступа к памяти устройства')),
        );
      }
      return;
    }
    final filtered = await LocalDb.fetchFiltered(
      from: _fromDate,
      to: _toDate,
    );
    final csvData = CsvService.generateCsv(filtered);

    String format(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    late final String fileName;
    if (_fromDate != null && _toDate != null) {
      fileName = 'Выгрузка записей за ${format(_fromDate!)} - ${format(_toDate!)}.csv';
    } else if (_fromDate != null) {
      fileName = 'Выгрузка записей с ${format(_fromDate!)}.csv';
    } else if (_toDate != null) {
      fileName = 'Выгрузка записей до ${format(_toDate!)}.csv';
    } else {
      fileName = 'Выгрузка всех записей.csv';
    }

    Directory? dir = await _selectDirectory();
    if (dir == null) {
      if (Platform.isAndroid) {
        final dirs =
        await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) dir = dirs.first;
      } else {
        dir = await getDownloadsDirectory();
      }
    }
    dir ??= await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/$fileName');
    try {
      await file.writeAsString(csvData, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить файл: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final appState = MyApp.of(ctx);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Экспорт'),
        actions: [
          IconButton(
            icon: Icon(appState.isDark ? Icons.sunny : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDark),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            title: const Text('Период'),
        trailing: DropdownButton<_PeriodPreset>(
          value: _preset,
          items: const [
            DropdownMenuItem(
              value: _PeriodPreset.last7,
              child: Text('Последние 7 дней'),
            ),
            DropdownMenuItem(
              value: _PeriodPreset.last30,
              child: Text('Последние 30 дней'),
            ),
            DropdownMenuItem(
              value: _PeriodPreset.thisMonth,
              child: Text('Текущий месяц'),
            ),
            DropdownMenuItem(
              value: _PeriodPreset.prevMonth,
              child: Text('Предыдущий месяц'),
            ),
            DropdownMenuItem(
              value: _PeriodPreset.allTime,
              child: Text('Весь период'),
            ),
            DropdownMenuItem(
              value: _PeriodPreset.manual,
              child: Text('Выбрать вручную'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _preset = v;
              if (_preset != _PeriodPreset.manual) {
                _applyPreset();
              }
            });
          },
              ),
            ),
        if (_preset == _PeriodPreset.manual) ...[
    ListTile(
    title: const Text('Дата от'),
    trailing: Text(
    _fromDate == null
    ? '—'
        : '${_fromDate!.day}.${_fromDate!.month}.${_fromDate!.year}',
    ),
    ListTile(
    title: const Text('Дата до'),
    trailing: Text(
    _toDate == null
    ? '—'
        : '${_toDate!.day}.${_toDate!.month}.${_toDate!.year}',
    ),
    onTap: () => _pickDate(isFrom: false),
    ),
    ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Сгенерировать PDF'),
              onPressed: _exportPdf,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Сохранить PDF'),
              onPressed: _savePdf,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_view),
              label: const Text('Выгрузить CSV'),
              onPressed: _exportCsv,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Сохранить CSV'),
              onPressed: _saveCsv,
            ),
          ],
        ),
      ),
    );
  }
}
