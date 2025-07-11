// lib/main.dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ← анонимная аутентификация
import 'package:flutter/material.dart';
import 'package:app_theme/app_theme.dart';
import 'theme/dark_diary_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/finance_tracker_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// flow_diary
import 'screens/flow_diary/achievements_screen.dart';
import 'screens/flow_diary/date_time_screen.dart';
import 'screens/flow_diary/development_screen.dart';
import 'screens/flow_diary/emotion_screen.dart';
import 'screens/flow_diary/focus_screen.dart';
import 'screens/flow_diary/state_screen.dart';
import 'screens/new_ui/evaluate_day_screen.dart';
import 'screens/new_ui/state_screen.dart';
import 'screens/new_ui/mood_screen.dart';
import 'screens/new_ui/achievements_screen_new.dart';
import 'screens/new_ui/development_screen_new.dart';
import 'screens/new_ui/focus_screen_new.dart';
import 'screens/new_ui/preview_screen_new.dart';

// history_diary - analytics
import 'screens/history_diary/analytics/analytics_menu_screen.dart';
import 'screens/history_diary/analytics/emotion_analytics_screen.dart';
import 'screens/history_diary/analytics/energy_analytics_screen.dart';
import 'screens/history_diary/analytics/rating_analytics_screen.dart';
import 'screens/history_diary/analytics/sleep_tracker_screen.dart';
import 'screens/history_diary/analytics/steps_analytics_screen.dart';
import 'screens/history_diary/analytics/correlations_screen.dart';
import 'screens/history_diary/analytics/highlights_screen.dart';
import 'screens/history_diary/analytics/manual_highlights_screen.dart';
import 'screens/history_diary/analytics/monthly_summary_screen.dart';
import 'screens/history_diary/analytics/activity_analytics_screen.dart';
import 'screens/history_diary/analytics/influence_analytics_screen.dart';

// history_diary - entries
import 'screens/history_diary/entries_screen.dart';
import 'screens/new_ui/my_records_screen.dart';
import 'screens/new_ui/entry_detail_screen_new.dart';
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
import 'screens/theme_example_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'services/permission_service.dart';
import 'services/notification_service.dart';
import 'app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  if (notificationsEnabled) {
    await NotificationService.init();
  }
  await NotificationService.init();
  //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  //await FirebaseAuth.instance.signInAnonymously();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationsEnabled) {
        NotificationService.requestPermission();
      }
    });
    // Анонимный вход без await, чтобы не блокировать UI
    //FirebaseAuth.instance
    //    .signInAnonymously()
    //    .then((cred) {
    //      debugPrint('Signed in as ${cred.user?.uid}');
    //    })
    //    .catchError((e) {
    //      debugPrint('Anonymous sign-in failed: $e');
    //    });
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
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.darkTheme,
      darkTheme: DarkDiaryTheme.theme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: HomeMenuScreen.routeName,
      routes: {
        DateTimeScreen.routeName:      (_) => const DateTimeScreen(),
        StateScreen.routeName:         (_) => const StateScreen(),
        StateScreenNew.routeName:      (_) => const StateScreenNew(),
        EmotionScreen.routeName:       (_) => const EmotionScreen(),
        MoodScreenNew.routeName:      (_) => const MoodScreenNew(),
        EvaluateDayScreen.routeName:   (_) => const EvaluateDayScreen(),
        AchievementsScreen.routeName:  (_) => const AchievementsScreen(),
        DevelopmentScreen.routeName:   (_) => const DevelopmentScreen(),
        FocusScreen.routeName:         (_) => const FocusScreen(),
        AchievementsScreenNew.routeName: (_) => const AchievementsScreenNew(),
        DevelopmentScreenNew.routeName: (_) => const DevelopmentScreenNew(),
        FocusScreenNew.routeName:       (_) => const FocusScreenNew(),
        PreviewScreenNew.routeName:    (_) => const PreviewScreenNew(),
        PreviewScreen.routeName:       (_) => const PreviewScreen(),
        MyRecordsScreen.routeName:       (_) => const MyRecordsScreen(),
        EntriesScreen.routeName:       (_) => const EntriesScreen(),
        EntryDetailScreenNew.routeName: (_) => const EntryDetailScreenNew(),
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
        HighlightsScreen.routeName: (_) => const HighlightsScreen(),
        ManualHighlightsScreen.routeName: (_) => const ManualHighlightsScreen(),
        MonthlySummaryScreen.routeName: (_) => const MonthlySummaryScreen(),
        ActivityAnalyticsScreen.routeName: (_) => const ActivityAnalyticsScreen(),
        InfluenceAnalyticsScreen.routeName: (_) => const InfluenceAnalyticsScreen(),
        HomeMenuScreen.routeName:  (_) => const HomeMenuScreen(),
        NotificationSettingsScreen.routeName: (_) => const NotificationSettingsScreen(),
        WorkoutAppScreen.routeName: (_) => const WorkoutAppScreen(),
        FinanceTrackerScreen.routeName: (_) => const FinanceTrackerScreen(),
        MyScreen.routeName: (_) => const MyScreen(),
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
