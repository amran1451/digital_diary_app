import 'package:flutter/material.dart';
import '../../models/entry_data.dart';
import '../../services/local_db.dart';
import 'entries_screen.dart';

class ImportPreviewScreen extends StatefulWidget {
  static const routeName = '/import/preview';
  const ImportPreviewScreen({Key? key}) : super(key: key);

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late List<EntryData> _entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entries = ModalRoute.of(context)!.settings.arguments as List<EntryData>;
  }

  Future<void> _saveAll() async {
    // Загрузим уже существующие даты
    final existing = await LocalDb.fetchAll();
    final existingDates = existing.map((e) => e.date).toSet();

    var saved = 0, skipped = 0;
    for (var entry in _entries) {
      if (existingDates.contains(entry.date)) {
        skipped++;
        continue;
      }
      await LocalDb.saveOrUpdate(entry);
      saved++;
      existingDates.add(entry.date);
    }

    final msg = StringBuffer()
      ..writeln('Импортировано $saved ${saved == 1 ? "запись" : "записей"}')
      ..write(skipped > 0 ? 'Пропущено дубликатов: $skipped' : '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg.toString().trim())),
    );

    // Вернуться к списку записей — он перезагрузит данные автоматически
    Navigator.popUntil(context, ModalRoute.withName(EntriesScreen.routeName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Предпросмотр импорта')),
      body: ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (ctx, idx) {
          final e = _entries[idx];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              title: Text('📅 ${e.date}   🕗 ${e.time}'),
              subtitle: Text('📊 Оценка: ${e.rating}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildField('Дата', e.date, (v) => e.date = v),
                      _buildField('Время', e.time, (v) => e.time = v),
                      _buildField('Оценка', e.rating, (v) => e.rating = v),
                      _buildField('Причина', e.ratingReason, (v) => e.ratingReason = v),
                      _buildField('Лёг в', e.bedTime, (v) => e.bedTime = v),
                      _buildField('Проснулся в', e.wakeTime, (v) => e.wakeTime = v),
                      _buildField('Сон', e.sleepDuration, (v) => e.sleepDuration = v),
                      _buildField('Шаги', e.steps, (v) => e.steps = v),
                      _buildField('Активность', e.activity, (v) => e.activity = v),
                      _buildField('Энергия', e.energy, (v) => e.energy = v),
                      _buildField('Настроение', e.mood, (v) => e.mood = v),
                      _buildField('Эмоции', e.mainEmotions, (v) => e.mainEmotions = v, maxLines: 2),
                      _buildField('Влияние', e.influence, (v) => e.influence = v, maxLines: 2),
                      _buildField('Важного', e.important, (v) => e.important = v, maxLines: 2),
                      _buildField('Задачи', e.tasks, (v) => e.tasks = v, maxLines: 2),
                      _buildField('Не успел', e.notDone, (v) => e.notDone = v, maxLines: 2),
                      _buildField('Мысль дня', e.thought, (v) => e.thought = v, maxLines: 2),
                      _buildField('Развитие', e.development, (v) => e.development = v),
                      _buildField('Качества', e.qualities, (v) => e.qualities = v),
                      _buildField('Улучшить (рост)', e.growthImprove, (v) => e.growthImprove = v),
                      _buildField('Приятное', e.pleasant, (v) => e.pleasant = v),
                      _buildField('Улучшить завтра', e.tomorrowImprove, (v) => e.tomorrowImprove = v),
                      _buildField('Шаг к цели', e.stepGoal, (v) => e.stepGoal = v),
                      _buildField('Поток мыслей', e.flow, (v) => e.flow = v, maxLines: 4),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отменить'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveAll,
                child: const Text('Импортировать все'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String initial,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initial);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
