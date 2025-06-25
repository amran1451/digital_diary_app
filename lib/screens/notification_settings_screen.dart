import 'package:flutter/material.dart';

import '../models/notification_settings.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  static const routeName = '/notification-settings';
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationSettings _settings;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _settings = await NotificationService.loadSettings();
    setState(() => _loaded = true);
  }

  String _freqLabel(int mins) {
    switch (mins) {
      case 60:
        return 'раз в час';
      case 180:
        return 'раз в 3 часа';
      case 720:
        return 'дважды в день';
      default:
        return '${(mins / 60).round()} ч';
    }
  }

  Future<void> _edit(String cat) async {
    final cs = _settings.categories[cat]!;
    int interval = cs.intervalMinutes;
    int start = cs.startHour;
    int end = cs.endHour;
    DayFilter day = cs.days;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: const Text('Настройка'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: interval,
                    items: const [
                      DropdownMenuItem(value: 60, child: Text('Каждый час')),
                      DropdownMenuItem(value: 180, child: Text('Каждые 3 часа')),
                      DropdownMenuItem(value: 720, child: Text('Дважды в день')),
                    ],
                    onChanged: (v) => setModal(() => interval = v ?? 180),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay(hour: start, minute: 0),
                          );
                          if (t != null) setModal(() => start = t.hour);
                        },
                        child: Text('От ${start.toString().padLeft(2, '0')}:00'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay(hour: end, minute: 0),
                          );
                          if (t != null) setModal(() => end = t.hour);
                        },
                        child: Text('До ${end.toString().padLeft(2, '0')}:00'),
                      ),
                    ],
                  ),
                  DropdownButton<DayFilter>(
                    value: day,
                    items: const [
                      DropdownMenuItem(value: DayFilter.any, child: Text('Все дни')),
                      DropdownMenuItem(value: DayFilter.workdays, child: Text('Будни')),
                      DropdownMenuItem(value: DayFilter.weekends, child: Text('Выходные')),
                    ],
                    onChanged: (v) => setModal(() => day = v ?? DayFilter.any),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    cs.intervalMinutes = interval;
    cs.startHour = start;
    cs.endHour = end;
    cs.days = day;
    setState(() {});
  }

  Future<void> _save() async {
    await NotificationService.updateSettings(_settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  void _reset() {
    setState(() => _settings = NotificationSettings.defaultSettings());
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки уведомлений')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ..._settings.categories.entries.map((e) {
              final cat = e.key;
              final cs = e.value;
              return Card(
                child: ListTile(
                  title: Text('$cat — ${_freqLabel(cs.intervalMinutes)}'),
                  trailing: Switch(
                    value: cs.enabled,
                    onChanged: (v) => setState(() => cs.enabled = v),
                  ),
                  onTap: () => _edit(cat),
                ),
              );
            }).toList(),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _reset, child: const Text('Сбросить')),
                ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}