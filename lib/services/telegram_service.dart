// lib/services/telegram_service.dart

import 'package:http/http.dart' as http;
import '../models/entry_data.dart';
import 'local_db.dart';

class TelegramService {
  static const _token = '7743223370:AAEvTi7V4_-FmL2Avb5TMNX0HTCpPn4xGqo';
  static const _chatId = '6870993533';

  /// Отправляет запись в телеграм и помечает её в локальной БД как синхронизированную.
  static Future<bool> sendEntry(EntryData e) async {
    final msg = _buildMessage(e);
    try {
      final res = await http.post(
        Uri.parse('https://api.telegram.org/bot$_token/sendMessage'),
        body: {'chat_id': _chatId, 'text': msg},
      );
      if (res.statusCode == 200) {
        if (e.localId != null) {
          await LocalDb.markSynced(e.localId!);
          e.needsSync = false;
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  static String _buildMessage(EntryData e) => '''
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
}
