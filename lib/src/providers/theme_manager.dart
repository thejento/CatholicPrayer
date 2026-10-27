import 'package:flutter/foundation.dart';

import '../data/preferences_store.dart';
import '../theme/app_theme.dart';

/// Manages the active [AppThemeMode] and persists the user's choice locally
/// so it survives app restarts, without requiring any account or sign-in.
class ThemeManager extends ChangeNotifier {
  ThemeManager(this._store);

  static const prefsKey = 'app_theme_mode';
  static const followSeasonKey = 'theme_follow_season';

  final PreferencesStore _store;

  AppThemeMode _mode = AppThemeMode.classic;
  AppThemeMode get mode => _mode;

  bool _followSeason = true;

  /// Whether the classic theme takes the colour of the liturgical season.
  bool get followSeason => _followSeason;

  /// Loads the previously saved theme, if any. Safe to call once at startup.
  Future<void> load() async {
    final saved = await _store.getString(prefsKey);
    final match = AppThemeMode.values.where((m) => m.name == saved);
    final follow = await _store.getBool(followSeasonKey) ?? true;
    if (match.isNotEmpty && match.first != _mode || follow != _followSeason) {
      if (match.isNotEmpty) _mode = match.first;
      _followSeason = follow;
      notifyListeners();
    }
  }

  Future<void> setFollowSeason(bool value) async {
    if (value == _followSeason) return;
    _followSeason = value;
    notifyListeners();
    await _store.setBool(followSeasonKey, value);
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _store.setString(prefsKey, mode.name);
  }
}
