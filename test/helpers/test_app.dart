import 'dart:convert';
import 'dart:io';

import 'package:crc/src/app.dart';
import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/domain/clock.dart';
import 'package:crc/src/providers/settings_controller.dart';
import 'package:crc/src/providers/theme_manager.dart';
import 'package:flutter/widgets.dart';

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Loads the real bundled content straight from disk (synchronously), so
/// widget tests do not need the asset bundle.
ContentRepository loadRealContent() => ContentRepository.fromJson(
  prayers: {for (final l in contentLanguages) l: _read('assets/data/prayers/$l.json')},
  mysteries: {for (final l in contentLanguages) l: _read('assets/data/mysteries/$l.json')},
);

/// A Monday: the Joyful mysteries are suggested.
final DateTime aMonday = DateTime(2026, 10, 12);

class TestApp {
  TestApp({Locale? locale, DateTime? now, PreferencesStore? store})
    : store = store ?? InMemoryPreferencesStore(),
      _now = now ?? aMonday {
    themeManager = ThemeManager(this.store);
    settings = SettingsController(this.store);
    if (locale != null) settings.setLocale(locale);
  }

  final PreferencesStore store;
  final DateTime _now;
  late final ThemeManager themeManager;
  late final SettingsController settings;

  Widget build() => CatholicPrayerApp(
    content: loadRealContent(),
    themeManager: themeManager,
    settings: settings,
    clock: Clock.fixed(_now),
  );
}
