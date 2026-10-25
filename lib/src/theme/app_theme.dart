import 'package:flutter/material.dart';

import '../domain/liturgical_calendar.dart';

/// The two visual themes the app supports: a subdued "Classic" look aimed at
/// adults, and a bright, playful "Kid-Friendly" look aimed at children.
enum AppThemeMode { classic, kidFriendly }

/// Builds the [ThemeData] for each [AppThemeMode].
class AppTheme {
  AppTheme._();

  /// The theme for [mode]. In the classic theme, [season] tints the app with
  /// the colour the Church wears that day (DESIGN §3.16); without it, classic
  /// keeps its maroon. The kid-friendly theme has its own colours all year.
  static ThemeData themeFor(AppThemeMode mode, {LiturgicalColor? season}) => switch (mode) {
    AppThemeMode.classic => _classic[season] ??= _classicTheme(classicSeed(season)),
    AppThemeMode.kidFriendly => _kidFriendlyTheme,
  };

  /// The seed of the classic palette: deep, muted tones of the vestment
  /// colours, so the screens stay calm. White days use gold, as white
  /// vestments are often trimmed with it.
  static Color classicSeed(LiturgicalColor? season) => switch (season) {
    null || LiturgicalColor.red => const Color(0xFF6B1E23), // deep liturgical maroon
    LiturgicalColor.green => const Color(0xFF2E5E3A),
    LiturgicalColor.violet => const Color(0xFF4A2C6E),
    LiturgicalColor.rose => const Color(0xFFC0508F),
    LiturgicalColor.white => const Color(0xFFA07A1F),
  };

  static final _classic = <LiturgicalColor?, ThemeData>{};

  static ThemeData _classicTheme(Color seed) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
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
