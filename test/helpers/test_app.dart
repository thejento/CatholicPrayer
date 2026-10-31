import 'dart:convert';
import 'dart:io';

import 'package:crc/src/app.dart';
import 'package:crc/src/audio/audio_catalog.dart';
import 'package:crc/src/data/art_catalog.dart';
import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/data/device_profile.dart';
import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/data/saints_repository.dart';
import 'package:crc/src/data/scripture_repository.dart';
import 'package:crc/src/domain/liturgical_calendar.dart';
import 'package:crc/src/domain/clock.dart';
import 'package:crc/src/providers/journal_controller.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:crc/src/providers/settings_controller.dart';
import 'package:crc/src/providers/theme_manager.dart';
import 'package:crc/src/reminders/reminder_controller.dart';
import 'package:flutter/widgets.dart';

import 'fake_clip_player.dart';
import 'fake_reminder_scheduler.dart';

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Loads the real bundled content straight from disk (synchronously), so
/// widget tests do not need the asset bundle.
ContentRepository loadRealContent() => ContentRepository.fromJson(
  prayers: {for (final l in contentLanguages) l: _read('assets/data/prayers/$l.json')},
  mysteries: {for (final l in contentLanguages) l: _read('assets/data/mysteries/$l.json')},
  notes: {for (final l in contentLanguages) l: _read(ContentRepository.notesPath(l))},
  learn: {for (final l in contentLanguages) l: _read(ContentRepository.learnPath(l))},
);

/// The real Bible passages.
ScriptureRepository loadRealScripture() => ScriptureRepository.fromJson({
  for (final l in contentLanguages) l: _read(ScriptureRepository.path(l)),
});

/// The real names of the saints.
SaintsRepository loadRealSaints() => SaintsRepository.fromJson({
  for (final l in contentLanguages) l: _read(SaintsRepository.path(l)),
});

/// The real artwork catalog.
ArtCatalog loadRealArt() => ArtCatalog.fromJson(_read(ArtCatalog.path));

/// The real voice manifest, so widget tests see the same languages as the app.
AudioCatalog loadRealAudio() => AudioCatalog.fromManifest(_read(AudioCatalog.manifestPath));

/// A Monday: the Joyful mysteries are suggested.
final DateTime aMonday = DateTime(2026, 10, 12);

class TestApp {
  TestApp({
    Locale? locale,
    DateTime? now,
    PreferencesStore? store,
    this.isTelevision = false,
    this.isAndroid = false,
    AudioCatalog? audio,
    CalendarRegion deviceRegion = CalendarRegion.general,
  }) : store = store ?? InMemoryPreferencesStore(),
       audio = audio ?? loadRealAudio(),
       _now = now ?? aMonday {
    themeManager = ThemeManager(this.store);
    settings = SettingsController(this.store, deviceRegion: deviceRegion);
    savedSession = SavedSessionController(this.store);
    journal = JournalController(this.store);
    reminder = ReminderController(
      this.store,
      reminders,
      available: DeviceProfile(isTelevision: isTelevision, isAndroid: isAndroid).supportsReminders,
    );
    if (locale != null) settings.setLocale(locale);
  }

  final PreferencesStore store;
  final DateTime _now;
  late final ThemeManager themeManager;
  late final SettingsController settings;
  late final SavedSessionController savedSession;
  late final JournalController journal;
  late final ReminderController reminder;
  final FakeReminderScheduler reminders = FakeReminderScheduler();
  final bool isTelevision;
  final bool isAndroid;
  final AudioCatalog audio;
  final FakeClipPlayer player = FakeClipPlayer();

  /// Links the app asked to open; [linksOpen] decides whether that succeeds.
  final List<Uri> openedLinks = [];
  bool linksOpen = true;

  Widget build() => CatholicPrayerApp(
    content: loadRealContent(),
    themeManager: themeManager,
    settings: settings,
    savedSession: savedSession,
    journal: journal,
    reminder: reminder,
    scripture: loadRealScripture(),
    saints: loadRealSaints(),
    art: loadRealArt(),
    device: DeviceProfile(isTelevision: isTelevision, isAndroid: isAndroid),
    audio: audio,
    playerFactory: () => player,
    clock: Clock.fixed(_now),
    linkOpener: (uri) async {
      openedLinks.add(uri);
      return linksOpen;
    },
  );
}
