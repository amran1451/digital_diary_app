// lib/screens/analytics_menu_screen.dart

import 'package:flutter/material.dart';
import 'rating_analytics_screen.dart';
import 'energy_analytics_screen.dart';
import 'emotion_analytics_screen.dart';
import 'sleep_tracker_screen.dart';
import 'steps_analytics_screen.dart';
import 'correlations_screen.dart';
import 'highlights_screen.dart';
import 'manual_highlights_screen.dart';
import 'monthly_summary_screen.dart';
import 'activity_analytics_screen.dart';
import 'influence_analytics_screen.dart';

class AnalyticsMenuScreen extends StatelessWidget {
  static const routeName = '/analytics';
  const AnalyticsMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _Tile(
              icon: Icons.show_chart,
              label: 'Оценки',
              color: theme.colorScheme.primary,
              onTap: () => Navigator.pushNamed(ctx, RatingAnalyticsScreen.routeName),
            ),
            _Tile(
              icon: Icons.bolt,
              label: 'Энергия',
              color: theme.colorScheme.secondary,
              onTap: () => Navigator.pushNamed(ctx, EnergyAnalyticsScreen.routeName),
            ),
            _Tile(
              icon: Icons.hotel,
              label: 'Сон',
              color: Colors.blueAccent,
              onTap: () => Navigator.pushNamed(ctx, SleepTrackerScreen.routeName),
            ),
            _Tile(
              icon: Icons.directions_walk,
              label: 'Шаги',
              color: Colors.deepOrange,
              onTap: () => Navigator.pushNamed(ctx, StepsAnalyticsScreen.routeName),
            ),
            _Tile(
              icon: Icons.emoji_emotions,
              label: 'Эмоции',
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(ctx, EmotionAnalyticsScreen.routeName),
            ),
            _Tile(
              icon: Icons.local_activity,
              label: 'Активность',
              color: Colors.orangeAccent,
              onTap: () => Navigator.pushNamed(ctx, ActivityAnalyticsScreen.routeName),
            ),
            _Tile(
              icon: Icons.tips_and_updates,
              label: 'Что повлияло',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(ctx, InfluenceAnalyticsScreen.routeName),
            ),
            _Tile(
              icon: Icons.auto_awesome,
              label: 'Ключевые моменты',
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(ctx, ManualHighlightsScreen.routeName),
            ),
            _Tile(
              icon: Icons.calendar_month,
              label: 'По месяцам',
              color: Colors.blueGrey,
              onTap: () => Navigator.pushNamed(ctx, MonthlySummaryScreen.routeName),
            ),
            _Tile(
              icon: Icons.multiline_chart,
              label: 'Корреляции',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(ctx, CorrelationsScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext c) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(c).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
