import '../models/entry_data.dart';

class TextExportService {
  static String buildEntryText(EntryData e) {
    final buffer = StringBuffer('''
📖 ДНЕВНИК | за ${e.date}
⏰ Создано: ${e.createdAtFormatted}
📊 Оценка: ${e.rating} – ${e.ratingReason}

😴 Сон: ${e.bedTime} → ${e.wakeTime} (${e.sleepDuration})
🚶 Шаги: ${e.steps}
🔥 Активность: ${e.activity}
⚡️ Энергия: ${e.energy}

😊 Настроение: ${e.mood}
🎭 Эмоции: ${e.mainEmotions}
💭 Влияние: ${e.influence}

✅ Важного: ${e.important}
📌 Задачи: ${e.tasks}
⏳ Не успел: ${e.notDone}
💡 Мысль: ${e.thought}

📖 Развитие: ${e.development}
💪 Качества: ${e.qualities}
🎯 Улучшить: ${e.growthImprove}

🌟 Приятное: ${e.pleasant}
🚀 Улучшить завтра: ${e.tomorrowImprove}
🎯 Шаг к цели: ${e.stepGoal}

💬 Поток мысли:
${e.flow}''');

    if (e.notificationsLog.isNotEmpty) {
      buffer.writeln('\n\n📌 Что происходило в течение дня');
      for (final n in e.notificationsLog) {
        final label = _typeLabel(n.type);
        final time = n.answerTime.isNotEmpty ? n.answerTime : n.sentTime;
        buffer.writeln('— $label в $time: ${n.text}');
      }
    }

    return buffer.toString();
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'thought':
        return 'мысль';
      case 'activity':
        return 'действие';
      case 'emotion':
        return 'эмоция';
      default:
        return 'заметка';
    }
  }

  static String buildEntriesText(List<EntryData> entries) {
    return entries.map(buildEntryText).join('\n\n-----\n\n');
  }
}