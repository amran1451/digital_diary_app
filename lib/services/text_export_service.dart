import '../models/entry_data.dart';

class TextExportService {
  static String buildEntryText(EntryData e) => '''
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
${e.flow}
''';

  static String buildEntriesText(List<EntryData> entries) {
    return entries.map(buildEntryText).join('\n\n-----\n\n');
  }
}