import 'package:flutter/material.dart';

import '../screens/new_ui/my_records_screen.dart';

enum DiaryMenuAction { entries }

class DiaryMenuButton extends StatelessWidget {
  const DiaryMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DiaryMenuAction>(
      onSelected: (action) {
        switch (action) {
          case DiaryMenuAction.entries:
            Navigator.pushNamed(context, MyRecordsScreen.routeName);
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: DiaryMenuAction.entries,
          child: ListTile(
            leading: Icon(Icons.list),
            title: Text('Мои записи'),
          ),
        ),
      ],
    );
  }
}
