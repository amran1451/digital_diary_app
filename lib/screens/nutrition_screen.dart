import 'package:flutter/material.dart';

class NutritionScreen extends StatelessWidget {
  static const routeName = '/analytics/nutrition';
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Учет питания')),
      body: const Center(child: Text('Здесь будет еда')),
    );
  }
}
