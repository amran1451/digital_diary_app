import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/models/limit.dart';
import 'package:finance_tracker/main.dart' as finance_app;

class FinanceTrackerScreen extends StatefulWidget {
  static const routeName = '/expenses';  // ← ключ для Navigator.pushNamed
  const FinanceTrackerScreen({Key? key}) : super(key: key);

  @override
  State<FinanceTrackerScreen> createState() => _FinanceTrackerScreenState();
}

class _FinanceTrackerScreenState extends State<FinanceTrackerScreen> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeFinance();
  }

  Future<void> _initializeFinance() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FinTransactionAdapter());
    Hive.registerAdapter(LimitAdapter());
    await Hive.openBox<FinTransaction>('transactions');
    await Hive.openBox<Limit>('limits');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const finance_app.MyApp();  // корень finance_tracker
      },
    );
  }
}
