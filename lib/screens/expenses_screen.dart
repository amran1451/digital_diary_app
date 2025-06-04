import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  static const routeName = '/analytics/expenses';
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Учет денег')),
      body: const Center(child: Text('Здесь будут деньги')),
    );
  }
}
