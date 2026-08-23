import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Manages the active [AppThemeMode] and persists the user's choice locally
/// so it survives app restarts, without requiring any account or sign-in.
class ThemeManager extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';

  ThemeManager({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  AppThemeMode _mode = AppThemeMode.classic;
  AppThemeMode get mode => _mode;

  /// Loads the previously saved theme, if any. Safe to call once at startup.
  Future<void> load() async {
    final saved = await _preferences.getString(_prefsKey);
    if (saved == AppThemeMode.kidFriendly.name) {
      _mode = AppThemeMode.kidFriendly;
      notifyListeners();
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _preferences.setString(_prefsKey, mode.name);
  }
}
