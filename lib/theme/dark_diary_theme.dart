import 'package:flutter/material.dart';

class DarkDiaryTheme {
  DarkDiaryTheme._();

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1B1B);
  static const Color primary = Color(0xFF9A7BFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFFFAD5C);
  static const Color outline = Color(0xFF3B3640);
  static const Color primaryContainer = Color(0xFF2B2730);

  static final TextTheme textTheme = const TextTheme(
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16),
    labelLarge: TextStyle(fontSize: 14),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      background: background,
      surface: surface,
      primary: primary,
      secondary: secondary,
      onPrimary: onPrimary,
      outline: outline,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(backgroundColor: surface),
  );
}