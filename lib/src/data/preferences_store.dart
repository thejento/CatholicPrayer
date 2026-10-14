import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key/value storage used for settings, so that tests can inject an
/// in-memory implementation.
abstract interface class PreferencesStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

/// [PreferencesStore] backed by `shared_preferences` (Android and web).
class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore([SharedPreferencesAsync? preferences])
    : _prefs = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<bool?> getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Volatile [PreferencesStore], used in tests.
class InMemoryPreferencesStore implements PreferencesStore {
  InMemoryPreferencesStore([Map<String, Object>? initial]) : values = {...?initial};

  final Map<String, Object> values;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}
