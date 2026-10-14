import 'package:flutter/foundation.dart';

import '../data/preferences_store.dart';
import '../theme/app_theme.dart';

/// Manages the active [AppThemeMode] and persists the user's choice locally
/// so it survives app restarts, without requiring any account or sign-in.
class ThemeManager extends ChangeNotifier {
  ThemeManager(this._store);

  static const prefsKey = 'app_theme_mode';

  final PreferencesStore _store;

  AppThemeMode _mode = AppThemeMode.classic;
  AppThemeMode get mode => _mode;

  /// Loads the previously saved theme, if any. Safe to call once at startup.
  Future<void> load() async {
    final saved = await _store.getString(prefsKey);
    final match = AppThemeMode.values.where((m) => m.name == saved);
    if (match.isNotEmpty && match.first != _mode) {
      _mode = match.first;
      notifyListeners();
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _store.setString(prefsKey, mode.name);
  }
}
