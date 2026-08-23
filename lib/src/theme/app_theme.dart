import 'package:flutter/material.dart';

/// The two visual themes the app supports: a subdued "Classic" look aimed at
/// adults, and a bright, playful "Kid-Friendly" look aimed at children.
enum AppThemeMode { classic, kidFriendly }

/// Builds the [ThemeData] for each [AppThemeMode].
class AppTheme {
  AppTheme._();

  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.classic:
        return _classicTheme;
      case AppThemeMode.kidFriendly:
        return _kidFriendlyTheme;
    }
  }

  static final ThemeData _classicTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B1E23), // deep liturgical maroon
      secondary: const Color(0xFFC9A227), // muted gold
      brightness: Brightness.light,
    ),
    fontFamily: 'serif',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );

  static final ThemeData _kidFriendlyTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E9CCA), // bright sky blue
      secondary: const Color(0xFFFFB020), // sunny orange
      brightness: Brightness.light,
    ),
    fontFamily: 'sans-serif',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontWeight: FontWeight.w800),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
