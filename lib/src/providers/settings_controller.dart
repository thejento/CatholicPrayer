import 'package:flutter/widgets.dart';

import '../data/preferences_store.dart';

/// User preferences other than the theme: language and newcomer guidance.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  static const localeKey = 'app_locale';
  static const guidanceKey = 'show_guidance';

  final PreferencesStore _store;

  Locale? _locale;
  bool _showGuidance = true;

  /// The chosen app language, or `null` to follow the device.
  Locale? get locale => _locale;

  /// Whether the "what to do" line is shown on each Rosary step.
  bool get showGuidance => _showGuidance;

  Future<void> load() async {
    final code = await _store.getString(localeKey);
    _locale = code == null ? null : Locale(code);
    _showGuidance = await _store.getBool(guidanceKey) ?? true;
    notifyListeners();
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
