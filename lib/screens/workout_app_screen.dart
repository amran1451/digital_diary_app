import 'package:flutter/material.dart';
import 'package:workout_app/main.dart' as workout_app;

class WorkoutAppScreen extends StatelessWidget {
  static const routeName = '/workout';

  const WorkoutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const workout_app.WorkoutApp();
  }
}