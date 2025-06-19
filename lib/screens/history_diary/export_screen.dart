import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

class _ExportScreenState extends State<ExportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

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
    // Получаем все локальные записи
    final all = await LocalDb.fetchAll();
    // Фильтруем в памяти по диапазону
    final filtered = all.where((e) {
      final dt = e.createdAt;
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt.isAfter(_toDate!)) return false;
      return true;
    }).toList();

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
    final all = await LocalDb.fetchAll();
    final filtered = all.where((e) {
      final dt = e.createdAt;
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt.isAfter(_toDate!)) return false;
      return true;
    }).toList();
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
    final all = await LocalDb.fetchAll();
    final filtered = all.where((e) {
      final dt = e.createdAt;
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt.isAfter(_toDate!)) return false;
      return true;
    }).toList();

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
    await file.writeAsBytes(pdfBytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: ${file.path}')),
    );
  }

  Future<void> _saveCsv() async {
    final all = await LocalDb.fetchAll();
    final filtered = all.where((e) {
      final dt = e.createdAt;
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt.isAfter(_toDate!)) return false;
      return true;
    }).toList();
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
    await file.writeAsString(csvData, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: ${file.path}')),
    );
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
            ListTile(
              title: const Text('Дата от'),
              trailing: Text(
                _fromDate == null
                    ? '—'
                    : '${_fromDate!.day}.${_fromDate!.month}.${_fromDate!.year}',
              ),
              onTap: () => _pickDate(isFrom: true),
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
