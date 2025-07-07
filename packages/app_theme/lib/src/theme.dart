import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static const _baseTextStyle = TextStyle(fontFamily: 'NotoSans');

  static final TextTheme _textTheme = TextTheme(
    displayLarge: _baseTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: _baseTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: _baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
    headlineMedium: _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    titleLarge: _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: _baseTextStyle.copyWith(fontSize: 14),
    bodyMedium: _baseTextStyle.copyWith(fontSize: 12),
    labelLarge: _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelSmall: _baseTextStyle.copyWith(fontSize: 12, color: Colors.grey),
  );

  static final ColorScheme _lightColors = const ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    background: backgroundColor,
    error: Colors.red,
  );

  static final ColorScheme _darkColors = const ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    background: darkBackgroundColor,
    error: Colors.red,
  );

  static ThemeData get lightTheme => ThemeData(
    colorScheme: _lightColors,
    textTheme: _textTheme,
    iconTheme: const IconThemeData(color: iconColor),
    appBarTheme: const AppBarTheme(backgroundColor: primaryColor),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _lightColors.primary,
      unselectedItemColor: _lightColors.onBackground.withOpacity(0.6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: _textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: _textTheme.labelLarge),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: _textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white),
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(iconColor: iconColor),
  );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    colorScheme: _darkColors,
    textTheme: _textTheme,
    iconTheme: const IconThemeData(color: Colors.white70),
    appBarTheme: const AppBarTheme(backgroundColor: primaryColor),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _darkColors.primary,
      unselectedItemColor: _darkColors.onBackground.withOpacity(0.6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: _textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: _textTheme.labelLarge),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: _textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white),
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colors.white70),
  );
}