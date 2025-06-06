// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ← анонимная аутентификация
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/finance_tracker_screen.dart';

// flow_diary
import 'screens/flow_diary/achievements_screen.dart';
import 'screens/flow_diary/date_time_screen.dart';
import 'screens/flow_diary/development_screen.dart';
import 'screens/flow_diary/emotion_screen.dart';
import 'screens/flow_diary/focus_screen.dart';
import 'screens/flow_diary/state_screen.dart';

// history_diary - analytics
import 'screens/history_diary/analytics/analytics_menu_screen.dart';
import 'screens/history_diary/analytics/emotion_analytics_screen.dart';
import 'screens/history_diary/analytics/energy_analytics_screen.dart';
import 'screens/history_diary/analytics/rating_analytics_screen.dart';
import 'screens/history_diary/analytics/sleep_tracker_screen.dart';
import 'screens/history_diary/analytics/steps_analytics_screen.dart';
import 'screens/history_diary/analytics/correlations_screen.dart';

// history_diary - entries
import 'screens/history_diary/entries_screen.dart';
import 'screens/history_diary/entry_detail_screen.dart';
import 'screens/history_diary/export_screen.dart';
import 'screens/history_diary/import_screen.dart';
import 'screens/history_diary/import_preview_screen.dart';

// send_diary
import 'screens/send_diary/preview_screen.dart';

// screens
import 'screens/home_menu_screen.dart';
import 'screens/workout_app_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/planner_screen.dart';

// экран второй прилы
import 'package:provider/provider.dart';
import 'package:nutrition_tracker/providers/theme_provider.dart';
import 'package:nutrition_tracker/providers/food_provider.dart';
import 'package:nutrition_tracker/providers/goal_provider.dart';
import 'package:nutrition_tracker/providers/plan_provider.dart';
import 'package:nutrition_tracker/providers/product_provider.dart';
import 'package:nutrition_tracker/app.dart';

import 'screens/planner_app_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    // Анонимный вход без await, чтобы не блокировать UI
    FirebaseAuth.instance
        .signInAnonymously()
        .then((cred) {
          debugPrint('Signed in as ${cred.user?.uid}');
        })
        .catchError((e) {
          debugPrint('Anonymous sign-in failed: $e');
        });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool('isDark') ?? false;
    });
  }

  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', value);
    setState(() => isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дневник',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: HomeMenuScreen.routeName,
      routes: {
        DateTimeScreen.routeName:      (_) => const DateTimeScreen(),
        StateScreen.routeName:         (_) => const StateScreen(),
        EmotionScreen.routeName:       (_) => const EmotionScreen(),
        AchievementsScreen.routeName:  (_) => const AchievementsScreen(),
        DevelopmentScreen.routeName:   (_) => const DevelopmentScreen(),
        FocusScreen.routeName:         (_) => const FocusScreen(),
        PreviewScreen.routeName:       (_) => const PreviewScreen(),
        EntriesScreen.routeName:       (_) => const EntriesScreen(),
        EntryDetailScreen.routeName:   (_) => const EntryDetailScreen(),
        ExportScreen.routeName:        (_) => const ExportScreen(),
        ImportScreen.routeName:        (_) => const ImportScreen(),
        ImportPreviewScreen.routeName: (_) => const ImportPreviewScreen(),
        RatingAnalyticsScreen.routeName: (_) => const RatingAnalyticsScreen(),
        SleepTrackerScreen.routeName: (_) => const SleepTrackerScreen(),
        AnalyticsMenuScreen.routeName: (_) => const AnalyticsMenuScreen(),
        EnergyAnalyticsScreen.routeName: (_) => const EnergyAnalyticsScreen(),
        StepsAnalyticsScreen.routeName: (_) => const StepsAnalyticsScreen(),
        CorrelationsScreen.routeName: (_) => const CorrelationsScreen(),
        HomeMenuScreen.routeName:  (_) => const HomeMenuScreen(),
        WorkoutAppScreen.routeName: (_) => const WorkoutAppScreen(),
        FinanceTrackerScreen.routeName: (_) => const FinanceTrackerScreen(),
        NutritionScreen.routeName: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider(false)),
            ChangeNotifierProvider(create: (_) => FoodProvider()),
            ChangeNotifierProvider(create: (_) => GoalProvider()),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
          ],
          child: const NutritionTrackerApp(),
        ),
        PlannerAppScreen.routeName: (_) => const PlannerAppScreen(),
        EmotionAnalyticsScreen.routeName: (_) => const EmotionAnalyticsScreen(),
      },
    );
  }
}
