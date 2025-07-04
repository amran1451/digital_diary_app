// lib/services/pdf_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/entry_data.dart';

class PdfService {
  /// Каждая запись — на своей странице, шрифт кириллицы + эмоджи.
  static Future<Uint8List> generatePdf(List<EntryData> entries) async {
    // Сортируем записи по дате создания от ранних к поздним
    final sortedEntries = entries.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    // Шрифты из assets/fonts/
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final fontEmoji = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoEmoji-Regular.ttf'),
    );

    // Документ с четырьмя слотами шрифтов:
    //   base/bold для обычного текста,
    //   italic/boldItalic — чтобы библиотека могла подхватить эмоджи.
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontEmoji,
        boldItalic: fontEmoji,
      ),
    );

    for (final e in sortedEntries) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Дневник — за ${e.date}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Создано: ${e.createdAtFormatted}', style: pw.TextStyle(fontSize: 12)),
                if (e.place.isNotEmpty)
                  pw.Text('Место: ${e.place}', style: pw.TextStyle(fontSize: 12)),
                pw.Divider(),

                pw.Text('Оценка дня: ${e.rating} — ${e.ratingReason}'),
                pw.SizedBox(height: 6),
                pw.Text('Сон: лег в ${e.bedTime} проснулся в ${e.wakeTime} спал (${e.sleepDuration})'),
                pw.Text('Шаги: ${e.steps}'),
                pw.Text('Активность: ${e.activity}'),
                pw.Text('Энергия: ${e.energy}'),
                pw.Text('Самочувствие: ${e.wellBeing == null || e.wellBeing == 'OK' || e.wellBeing!.isEmpty ? 'Всё хорошо' : e.wellBeing}'),
                pw.Divider(),

                pw.Text('Настроение и эмоции',
                    style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                pw.Text('Настроение: ${e.mood}'),
                pw.Text('Эмоции: ${e.mainEmotions}'),
                pw.Text('Влияние: ${e.influence}'),
                pw.Divider(),

                pw.Text('Достижения и мысли',
                    style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                pw.Text('Важного: ${e.important}'),
                pw.Text('Задачи: ${e.tasks}'),
                pw.Text('Не успел: ${e.notDone}'),
                pw.Text('Мысль дня: ${e.thought}'),
                pw.Divider(),

                pw.Text('Развитие',
                    style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                pw.Text('Развитие: ${e.development}'),
                pw.Text('Качества: ${e.qualities}'),
                pw.Text('Улучшить: ${e.growthImprove}'),
                pw.Divider(),

                pw.Text('Итоги и планы',
                    style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                pw.Text('Приятное: ${e.pleasant}'),
                pw.Text('Улучшить: ${e.tomorrowImprove}'),
                pw.Text('Шаг к цели: ${e.stepGoal}'),
                pw.Divider(),

                pw.Text('Поток мыслей:',
                    style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                pw.Text(e.flow),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
