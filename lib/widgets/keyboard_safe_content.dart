import 'package:flutter/material.dart';

/// Padding wrapper that uses [MediaQuery.viewInsets] to keep content
/// visible above the on-screen keyboard.
class KeyboardSafeContent extends StatelessWidget {
  final Widget child;

  const KeyboardSafeContent({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: child,
    );
  }
}