import 'package:flutter/material.dart';

import '../data/preferences_store.dart';
import 'reminder_scheduler.dart';

/// Localized texts of the reminder, provided by the UI layer.
@immutable
class ReminderTexts {
  const ReminderTexts({required this.title, required this.channelName, required this.bodies});

  final String title;
  final String channelName;

  /// Notification body per weekday ([DateTime.monday]..[DateTime.sunday]).
  final Map<int, String> bodies;

  @override
  bool operator ==(Object other) =>
      other is ReminderTexts &&
      other.title == title &&
      other.channelName == channelName &&
      [for (var d = 1; d <= 7; d++) other.bodies[d] == bodies[d]].every((same) => same);

  @override
  int get hashCode => Object.hash(title, channelName, Object.hashAll(bodies.values));
}

/// The daily reminder setting (F-12, ADR-023): on/off and time, persisted, and
/// kept in sync with the platform schedule.
class ReminderController extends ChangeNotifier {
  ReminderController(this._store, this._scheduler, {required this.available});

  static const enabledKey = 'reminder_enabled';
  static const timeKey = 'reminder_minutes';
  static const defaultTime = TimeOfDay(hour: 20, minute: 0);

  final PreferencesStore _store;
  final ReminderScheduler _scheduler;

  /// False where reminders are not offered (web, Android TV).
  final bool available;

  bool _enabled = false;
  TimeOfDay _time = defaultTime;
  ReminderTexts? _texts;

  bool get enabled => _enabled;
  TimeOfDay get time => _time;

  Future<void> load() async {
    _enabled = await _store.getBool(enabledKey) ?? false;
    final minutes = int.tryParse(await _store.getString(timeKey) ?? '');
    if (minutes != null && minutes >= 0 && minutes < 24 * 60) {
      _time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }
    notifyListeners();
  }

  /// Turns the reminder on or off. Turning it on asks for permission first;
  /// returns false (and stays off) if it is refused.
  Future<bool> setEnabled(bool value) async {
    if (value && !await _scheduler.requestPermission()) return false;
    _enabled = value;
    notifyListeners();
    await _store.setBool(enabledKey, value);
    await _sync();
    return true;
  }

  Future<void> setTime(TimeOfDay time) async {
    if (time == _time) return;
    _time = time;
    notifyListeners();
    await _store.setString(timeKey, '${time.hour * 60 + time.minute}');
    await _sync();
  }

  /// Called with the current language's texts; reschedules when they change.
  Future<void> updateTexts(ReminderTexts texts) async {
    if (texts == _texts) return;
    _texts = texts;
    await _sync();
  }

  Future<void> _sync() async {
    final texts = _texts;
    if (!available || texts == null) return;
    if (!_enabled) {
      await _scheduler.cancelAll();
      return;
    }
    await _scheduler.schedule([
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        WeeklyReminder(
          weekday: day,
          hour: _time.hour,
          minute: _time.minute,
          title: texts.title,
          body: texts.bodies[day]!,
        ),
    ], channelName: texts.channelName);
  }
}

/// Used where reminders are not offered: does nothing.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(List<WeeklyReminder> reminders, {required String channelName}) async {}

  @override
  Future<void> cancelAll() async {}
}
