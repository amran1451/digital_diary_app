import 'package:flutter/material.dart';
import '../main.dart';
import 'workout_app_screen.dart';
import 'expenses_screen.dart';
import 'nutrition_screen.dart';
import 'planner_screen.dart';
import 'history_diary/entries_screen.dart';
import 'flow_diary/date_time_screen.dart';
import 'finance_tracker_screen.dart';
import 'planner_app_screen.dart';
import 'notification_settings_screen.dart';
import '../app_config.dart';
import 'new_ui/evaluate_day_screen.dart';

class HomeMenuScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeMenuScreen({Key? key}) : super(key: key);

  Widget _buildTile(BuildContext c, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(c, route),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(c).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(c).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: Theme.of(c).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Главное меню')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildTile(c, Icons.fitness_center, 'Тренировки', WorkoutAppScreen.routeName),
              _buildTile(c, Icons.attach_money, 'Расходы', FinanceTrackerScreen.routeName),
              _buildTile(c, Icons.restaurant, 'Питание',    NutritionScreen.routeName),
              _buildTile(c, Icons.check_box, 'Планер', PlannerAppScreen.routeName),
              _buildTile(c, Icons.book,   'Дневник',         DateTimeScreen.routeName),
              if (notificationsEnabled)
                _buildTile(c, Icons.notifications, 'Уведомления', NotificationSettingsScreen.routeName),
              _buildTile(c, Icons.book,   'Дневник 2.0',         EvaluateDayScreen.routeName),
            ],
          ),
        ),
      ),
    );
  }
}
