import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/providers/settings_controller.dart';
import 'package:crc/src/providers/theme_manager.dart';
import 'package:crc/src/theme/app_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeManager', () {
    test('defaults to classic and persists changes', () async {
      final store = InMemoryPreferencesStore();
      final manager = ThemeManager(store);
      await manager.load();
      expect(manager.mode, AppThemeMode.classic);

      await manager.setMode(AppThemeMode.kidFriendly);
      expect(store.values[ThemeManager.prefsKey], 'kidFriendly');

      final reloaded = ThemeManager(store);
      await reloaded.load();
      expect(reloaded.mode, AppThemeMode.kidFriendly);
    });

    test('follows the liturgical season by default and remembers turning it off', () async {
      final store = InMemoryPreferencesStore();
      final manager = ThemeManager(store);
      await manager.load();
      expect(manager.followSeason, isTrue);

      await manager.setFollowSeason(false);
      expect(store.values[ThemeManager.followSeasonKey], false);
      await manager.setFollowSeason(false);

      final reloaded = ThemeManager(store);
      await reloaded.load();
      expect(reloaded.followSeason, isFalse);
      expect(reloaded.mode, AppThemeMode.classic);
    });

    test('ignores unknown saved values', () async {
      final manager = ThemeManager(InMemoryPreferencesStore({ThemeManager.prefsKey: 'neon'}));
      await manager.load();
      expect(manager.mode, AppThemeMode.classic);
    });

    test('does not notify when the mode is unchanged', () async {
      final manager = ThemeManager(InMemoryPreferencesStore());
      var calls = 0;
      manager.addListener(() => calls++);
      await manager.setMode(AppThemeMode.classic);
      expect(calls, 0);
    });
  });

  group('SettingsController', () {
    test('defaults to device language and guidance on', () async {
      final settings = SettingsController(InMemoryPreferencesStore());
      await settings.load();
      expect(settings.locale, isNull);
      expect(settings.showGuidance, isTrue);
    });

    test('persists language and guidance', () async {
      final store = InMemoryPreferencesStore();
      final settings = SettingsController(store);
      await settings.setLocale(const Locale('es'));
      await settings.setShowGuidance(false);

      final reloaded = SettingsController(store);
      await reloaded.load();
      expect(reloaded.locale, const Locale('es'));
      expect(reloaded.showGuidance, isFalse);
    });

    test('clearing the language removes it', () async {
      final store = InMemoryPreferencesStore();
      final settings = SettingsController(store);
      await settings.setLocale(const Locale('fr'));
      await settings.setLocale(null);
      expect(store.values.containsKey(SettingsController.localeKey), isFalse);
    });
  });

  group('voice settings', () {
    test('default to off, normal speed, 2 s pause, guidance read aloud, auto-scroll', () async {
      final settings = SettingsController(InMemoryPreferencesStore());
      await settings.load();
      expect(settings.voiceEnabled, isFalse);
      expect(settings.voiceSpeed, 1.0);
      expect(settings.autoAdvance, isFalse);
      expect(settings.pauseSeconds, 2);
      expect(settings.readGuidanceAloud, isTrue);
      expect(settings.autoScroll, isTrue);
    });

    test('persist and clamp out-of-range values', () async {
      final store = InMemoryPreferencesStore();
      final settings = SettingsController(store);
      await settings.setVoiceSpeed(3);
      await settings.setPauseSeconds(0);
      expect(settings.voiceSpeed, SettingsController.maxSpeed);
      expect(settings.pauseSeconds, SettingsController.minPause);

      store.values[SettingsController.voiceSpeedKey] = '0.1';
      store.values[SettingsController.pauseKey] = 'junk';
      final reloaded = SettingsController(store);
      await reloaded.load();
      expect(reloaded.voiceSpeed, SettingsController.minSpeed);
      expect(reloaded.pauseSeconds, 2);
    });
  });
}
