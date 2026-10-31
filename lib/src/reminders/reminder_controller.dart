import 'package:flutter/material.dart';

import '../data/preferences_store.dart';
import '../domain/clock.dart';
import '../domain/mysteries.dart';
import 'reminder_scheduler.dart';

/// Localized texts of the reminder, provided by the UI layer.
@immutable
class ReminderTexts {
  const ReminderTexts({required this.title, required this.channelName, required this.bodies});

  final String title;
  final String channelName;

  /// Notification body naming each set of mysteries.
  final Map<MysterySet, String> bodies;

  @override
  bool operator ==(Object other) =>
      other is ReminderTexts &&
      other.title == title &&
      other.channelName == channelName &&
      MysterySet.values.every((s) => other.bodies[s] == bodies[s]);

  @override
  int get hashCode =>
      Object.hash(title, channelName, Object.hashAll(MysterySet.values.map((s) => bodies[s])));
}

/// What became of turning the reminder on or off.
enum ReminderChange { done, denied, failed }

/// The daily reminder setting (F-12, ADR-023): on/off and time, persisted, and
/// kept in sync with the platform schedule.
class ReminderController extends ChangeNotifier {
  ReminderController(
    this._store,
    this._scheduler, {
    required this.available,
    this.clock = const Clock(),
  });

  static const enabledKey = 'reminder_enabled';
  static const timeKey = 'reminder_minutes';
  static const defaultTime = TimeOfDay(hour: 20, minute: 0);

  /// Days scheduled ahead, one notification each, each naming that date's
  /// mysteries (r-12). Renewed whenever the app starts; well under Android's
  /// limit of 500 alarms per app.
  static const daysAhead = 84;

  final PreferencesStore _store;
  final ReminderScheduler _scheduler;

  /// False where reminders are not offered (web, Android TV).
  final bool available;
  final Clock clock;

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

  /// Turns the reminder on or off. Turning it on asks for permission first
  /// and stays off if it is refused, or if the reminders can't be scheduled.
  Future<ReminderChange> setEnabled(bool value) async {
    try {
      if (value && !await _scheduler.requestPermission()) return ReminderChange.denied;
    } catch (error) {
      debugPrint('Reminder: permission request failed: $error');
      return ReminderChange.failed;
    }
    _enabled = value;
    notifyListeners();
    await _store.setBool(enabledKey, value);
    if (await _sync() || !value) return ReminderChange.done;
    _enabled = false;
    notifyListeners();
    await _store.setBool(enabledKey, false);
    return ReminderChange.failed;
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
    // Tried again with the next texts, e.g. at the next start.
    if (!await _sync()) _texts = null;
  }

  /// Brings the platform schedule in line; returns false if it failed, which
  /// never escapes as an error (r-11).
  Future<bool> _sync() async {
    final texts = _texts;
    if (!available || texts == null) return true;
    try {
      if (!_enabled) {
        await _scheduler.cancelAll();
      } else {
        await _scheduler.schedule(_reminders(texts), channelName: texts.channelName);
      }
      return true;
    } catch (error) {
      debugPrint('Reminder: scheduling failed: $error');
      return false;
    }
  }

  /// One per day from the next [time], with that date's mysteries.
  List<Reminder> _reminders(ReminderTexts texts) {
    final now = clock.now();
    DateTime day(int offset) =>
        DateTime(now.year, now.month, now.day + offset, _time.hour, _time.minute);
    final first = day(0).isAfter(now) ? 0 : 1;
    return [
      for (var i = 0; i < daysAhead; i++)
        if (day(first + i) case final at)
          Reminder(
            id: 100 + i,
            at: at,
            title: texts.title,
            body: texts.bodies[suggestedMysterySet(at)]!,
          ),
    ];
  }
}

/// Used where reminders are not offered: does nothing.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(List<Reminder> reminders, {required String channelName}) async {}

  @override
  Future<void> cancelAll() async {}
}
