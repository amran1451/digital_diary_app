import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planner_app/main.dart'    as planner_app;
import 'package:planner_app/providers/task_provider.dart';

class PlannerAppScreen extends StatelessWidget {
  static const routeName = '/planner';  // должно совпадать с HomeMenuScreen
  const PlannerAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: const planner_app.MyApp(),
    );
  }
}
