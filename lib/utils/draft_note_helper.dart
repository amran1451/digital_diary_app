import 'package:flutter/material.dart';
import '../services/quick_note_service.dart';

class DraftNoteHelper {
  static Future<String?> editNote(
      BuildContext context, String date, String field, String initial) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Черновая заметка'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Текст заметки'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null) {
      await QuickNoteService.saveNote(date, field, result);
      return result;
    }
    return null;
  }

  static Widget buildBanner(
      {required String? note,
        required VoidCallback onApply,
        EdgeInsetsGeometry? padding}) {
    if (note == null || note.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(note)),
          TextButton(onPressed: onApply, child: const Text('Перенести')),
        ],
      ),
    );
  }
}