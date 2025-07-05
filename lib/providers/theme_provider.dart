import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.cyan,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.cyan[50],
        foregroundColor: Colors.grey[800],
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.cyan,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.grey[800],
        surfaceTintColor: Colors.grey[800],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
    );
  }
}
