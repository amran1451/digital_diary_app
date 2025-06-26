import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static const _baseTextStyle = TextStyle(fontFamily: 'NotoSans');

  static TextTheme get _textTheme => const TextTheme(
    headline1: _baseTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    headline2: _baseTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
    headline3: _baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
    headline4: _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    headline5: _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    headline6: _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    bodyText1: _baseTextStyle.copyWith(fontSize: 14),
    bodyText2: _baseTextStyle.copyWith(fontSize: 12),
    button: _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    caption: _baseTextStyle.copyWith(fontSize: 12, color: Colors.grey),
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
        textStyle: _textTheme.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: _textTheme.button),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: _textTheme.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardTheme(
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
        textStyle: _textTheme.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: _textTheme.button),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: _textTheme.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colors.white70),
  );
}