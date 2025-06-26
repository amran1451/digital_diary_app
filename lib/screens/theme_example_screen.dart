import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  static const routeName = '/theme-example';
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: Text('Заголовок', style: theme.textTheme.titleLarge)),
      body: Center(
        child: ElevatedButton(
          style: theme.elevatedButtonTheme.style,
          onPressed: () {},
          child: Text('Кнопка', style: theme.textTheme.labelLarge),
        ),
      ),
    );
  }
}