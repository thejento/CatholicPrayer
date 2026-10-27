import 'package:flutter/widgets.dart';

import '../data/preferences_store.dart';
import '../domain/liturgical_calendar.dart';
import '../domain/rosary_sequence.dart';

/// User preferences other than the theme: language and newcomer guidance.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store, {this.deviceRegion = CalendarRegion.general});

  static const localeKey = 'app_locale';
  static const guidanceKey = 'show_guidance';
  static const voiceKey = 'voice_enabled';
  static const voiceSpeedKey = 'voice_speed';
  static const autoAdvanceKey = 'auto_advance';
  static const pauseKey = 'auto_advance_pause_seconds';
  static const guidanceAloudKey = 'read_guidance_aloud';
  static const autoScrollKey = 'auto_scroll';
  static const rosaryModeKey = 'rosary_mode';
  static const regionKey = 'calendar_region';

  /// The calendar of the device's country, used until one is chosen.
  final CalendarRegion deviceRegion;

  /// The national calendar for a device country code (`CA`, `US` …).
  static CalendarRegion regionForCountry(String? countryCode) =>
      switch (countryCode?.toUpperCase()) {
        'CA' => CalendarRegion.canada,
        'US' => CalendarRegion.unitedStates,
        _ => CalendarRegion.general,
      };

  /// Allowed playback speeds and pauses (DESIGN §3.7).
  static const minSpeed = 0.75, maxSpeed = 1.25;
  static const minPause = 1, maxPause = 5;

  final PreferencesStore _store;

  Locale? _locale;
  bool _showGuidance = true;
  bool _voiceEnabled = false;
  double _voiceSpeed = 1.0;
  bool _autoAdvance = false;
  int _pauseSeconds = 2;
  bool _readGuidanceAloud = true;
  bool _autoScroll = true;
  RosaryMode _rosaryMode = RosaryMode.guided;
  CalendarRegion? _region;

  /// The chosen app language, or `null` to follow the device.
  Locale? get locale => _locale;

  /// Whether the "what to do" line is shown on each Rosary step.
  bool get showGuidance => _showGuidance;

  /// Whether the Rosary is read aloud.
  bool get voiceEnabled => _voiceEnabled;

  /// Playback speed of the voice, from [minSpeed] to [maxSpeed].
  double get voiceSpeed => _voiceSpeed;

  /// Whether to move on automatically when the voice finishes a prayer.
  bool get autoAdvance => _autoAdvance;

  /// Silence before auto-advancing, from [minPause] to [maxPause] seconds.
  int get pauseSeconds => _pauseSeconds;

  /// Whether the voice also reads the "what to do" line.
  bool get readGuidanceAloud => _readGuidanceAloud;

  /// Whether a long prayer scrolls along while the voice reads it.
  bool get autoScroll => _autoScroll;

  /// Guided or mysteries only, as last chosen on the mystery picker.
  RosaryMode get rosaryMode => _rosaryMode;

  /// The liturgical calendar followed: the chosen one, or the device's.
  CalendarRegion get calendarRegion => _region ?? deviceRegion;

  Future<void> load() async {
    final code = await _store.getString(localeKey);
    _locale = code == null ? null : Locale(code);
    _showGuidance = await _store.getBool(guidanceKey) ?? true;
    _voiceEnabled = await _store.getBool(voiceKey) ?? false;
    _voiceSpeed = (double.tryParse(await _store.getString(voiceSpeedKey) ?? '') ?? 1.0).clamp(
      minSpeed,
      maxSpeed,
    );
    _autoAdvance = await _store.getBool(autoAdvanceKey) ?? false;
    _pauseSeconds = (int.tryParse(await _store.getString(pauseKey) ?? '') ?? 2).clamp(
      minPause,
      maxPause,
    );
    _readGuidanceAloud = await _store.getBool(guidanceAloudKey) ?? true;
    _autoScroll = await _store.getBool(autoScrollKey) ?? true;
    final mode = await _store.getString(rosaryModeKey);
    _rosaryMode = RosaryMode.values.where((m) => m.name == mode).firstOrNull ?? RosaryMode.guided;
    final region = await _store.getString(regionKey);
    _region = CalendarRegion.values.where((r) => r.name == region).firstOrNull;
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) =>
      _setBool(voiceKey, value, () => _voiceEnabled = value);

  Future<void> setAutoAdvance(bool value) =>
      _setBool(autoAdvanceKey, value, () => _autoAdvance = value);

  Future<void> setReadGuidanceAloud(bool value) =>
      _setBool(guidanceAloudKey, value, () => _readGuidanceAloud = value);

  Future<void> setRosaryMode(RosaryMode value) async {
    if (value == _rosaryMode) return;
    _rosaryMode = value;
    notifyListeners();
    await _store.setString(rosaryModeKey, value.name);
  }

  Future<void> setCalendarRegion(CalendarRegion value) async {
    if (value == _region) return;
    _region = value;
    notifyListeners();
    await _store.setString(regionKey, value.name);
  }

  Future<void> setAutoScroll(bool value) =>
      _setBool(autoScrollKey, value, () => _autoScroll = value);

  Future<void> setVoiceSpeed(double value) async {
    value = value.clamp(minSpeed, maxSpeed);
    if (value == _voiceSpeed) return;
    _voiceSpeed = value;
    notifyListeners();
    await _store.setString(voiceSpeedKey, value.toString());
  }

  Future<void> setPauseSeconds(int value) async {
    value = value.clamp(minPause, maxPause);
    if (value == _pauseSeconds) return;
    _pauseSeconds = value;
    notifyListeners();
    await _store.setString(pauseKey, value.toString());
  }

  Future<void> _setBool(String key, bool value, void Function() apply) async {
    apply();
    notifyListeners();
    await _store.setBool(key, value);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _store.remove(localeKey);
    } else {
      await _store.setString(localeKey, locale.languageCode);
    }
  }

  Future<void> setShowGuidance(bool value) async {
    if (value == _showGuidance) return;
    _showGuidance = value;
    notifyListeners();
    await _store.setBool(guidanceKey, value);
  }
}
