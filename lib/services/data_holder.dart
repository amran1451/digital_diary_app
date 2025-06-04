// lib/services/data_holder.dart
class DataHolder {
  static String date = '';
  static String time = '';
  static bool useCloud = true;
  static String rating = '', reason = '', sleep = '', steps = '', activity = '', energy = '';
  static String mood = '', emotions = '', influence = '';
  static String done = '', tasksCompleted = '', missed = '', keyThought = '';
  static String development = '', qualities = '', improveTomorrow = '', pleasant = '', focus = '', step = '', stream = '';

  static String buildMessage() => '''📖 ДНЕВНИК | $date
⏳ Время записи: $time
📊 Оценка дня (0–10) и причина: $rating – $reason

🔹 Физическое состояние
😴 Сон: $sleep
🚶 Шаги: $steps
🔥 Активность: $activity
⚡️ Энергия (0–10): $energy

🔹 Настроение и эмоции
😊 Общее настроение: $mood
🎭 Главные эмоции дня: $emotions
💭 Что повлияло на настроение? $influence

🔹 Достижения и продуктивность
✅ Что сделал важного? $done
📌 Задачи: $tasksCompleted
⏳ Не успел и почему? $missed
💡 Самая важная мысль дня: $keyThought

🔹 Личностный рост
📖 Как развивался? $development
💪 Личные качества: $qualities
🎯 Что улучшить завтра? $improveTomorrow

🔹 Итоги и фокус на завтра
🌟 Приятный момент дня: $pleasant
🚀 Что можно улучшить завтра? $focus
🎯 Шаг к цели: $step

💬 Поток мыслей:
$stream
''';
}