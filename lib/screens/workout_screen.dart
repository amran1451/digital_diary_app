import 'package:flutter/material.dart';

class WorkoutScreen extends StatelessWidget {
  static const routeName = '/analytics/workout';
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Учет тренировок')),
      body: const Center(child: Text('Здесь будет аналитика тренировок')),
    );
  }
}
