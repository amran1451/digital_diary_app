import 'package:flutter/material.dart';
import '../services/quick_note_service.dart';

class DraftNoteHelper {
  static Future<QuickNote?> addNote(
      BuildContext context, String date, String field) async {
    final ctrl = TextEditingController();
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
    if (result != null && result.trim().isNotEmpty) {
      return await QuickNoteService.addNote(date, field, result.trim());
    }
    return null;
  }

  static Widget buildNotesList({
    required List<QuickNote> notes,
    required void Function(int) onApply,
    required void Function(int) onDelete,
  }) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (int i = 0; i < notes.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('— ${notes[i].time}: ${notes[i].text}'),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Перенести',
                  onPressed: () => onApply(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDelete(i),
                ),
              ],
            ),
          ),
      ],
    );
  }
}