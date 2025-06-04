import 'package:flutter/material.dart';

class PlannerScreen extends StatelessWidget {
  static const routeName = '/analytics/planner';
  const PlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Планер')),
      body: const Center(child: Text('Здесь будут планы')),
    );
  }
}
