import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/entry_data.dart';

class CloudDb {
  /// Обычный дамп в Firestore (используется при первой отправке из PreviewScreen).
  static Future<void> save(EntryData entry) async {
    await FirebaseFirestore.instance
        .collection('entries')
        .add(entry.toMap());
  }

  static Future<List<EntryData>> fetchAll() async {
    final snap = await FirebaseFirestore.instance
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => EntryData.fromMap(d.data(), id: d.id))
        .toList();
  }

  static Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('entries').doc(id).delete();
  }

  static Future<void> clearAll() async {
    final batch = FirebaseFirestore.instance.batch();
    final snap =
        await FirebaseFirestore.instance.collection('entries').get();
    for (var doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  /// Синхронизует одну запись:
  /// 1) кладёт её в Firestore,
  /// 2) шлёт тот же текст в Telegram,
  /// 3) возвращает true, если всё прошло без исключений.
  static Future<bool> syncOne(EntryData e) async {
    const token = '7743223370:AAEvTi7V4_-FmL2Avb5TMNX0HTCpPn4xGqo';
    const chatId = '6870993533';
    final msg = e.raw.isNotEmpty ? e.raw : '''
📖 ДНЕВНИК | за ${e.date}
⏰ Создано: ${e.createdAtFormatted}
📊 Оценка дня – причина: ${e.rating} – ${e.ratingReason}

🔹 Физическое состояние
😴 Сон: ${e.bedTime} → ${e.wakeTime} (${e.sleepDuration})
🚶 Шаги: ${e.steps}
🔥 Активность: ${e.activity}
⚡️ Энергия: ${e.energy}
🤒 Самочувствие: ${e.wellBeing == null || e.wellBeing == 'OK' || e.wellBeing!.isEmpty ? 'Всё хорошо' : e.wellBeing}

🔹 Настроение и эмоции
😊 Настроение: ${e.mood}
🎭 Главные эмоции: ${e.mainEmotions}
💭 Что повлияло: ${e.influence}

🔹 Достижения
✅ Сделал важного: ${e.important}
📌 Задачи: ${e.tasks}
⏳ Не успел: ${e.notDone}
💡 Мысль дня: ${e.thought}

🔹 Развитие
📖 Развивался: ${e.development}
💪 Качества: ${e.qualities}
🎯 Улучшить: ${e.growthImprove}

🔹 Итоги
🌟 Приятное: ${e.pleasant}
🚀 Что улучшить: ${e.tomorrowImprove}
🎯 Шаг к цели: ${e.stepGoal}

💬 Поток мыслей:
${e.flow}
''';
    try {
      // 1) Firestore
      await FirebaseFirestore.instance
          .collection('entries')
          .add(e.toMap());
      // 2) Telegram
      await http.post(
        Uri.parse('https://api.telegram.org/bot$token/sendMessage'),
        body: {'chat_id': chatId, 'text': msg},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
