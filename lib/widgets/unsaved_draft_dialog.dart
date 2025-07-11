import 'package:flutter/material.dart';

Future<bool?> showUnsavedDraftDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Есть незавершённая запись'),
      content: const Text('Ты начал(а) заполнять дневник, но не сохранил(а). Продолжить?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Начать заново'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Продолжить'),
        ),
      ],
    ),
  );
}