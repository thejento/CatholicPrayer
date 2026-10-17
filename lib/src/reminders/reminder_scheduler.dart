import 'package:flutter/foundation.dart';

/// One weekly notification: [weekday] uses [DateTime.monday]..[DateTime.sunday].
@immutable
class WeeklyReminder {
  const WeeklyReminder({
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });

  final int weekday;
  final int hour;
  final int minute;
  final String title;
  final String body;

  /// Stable notification id, so rescheduling replaces rather than duplicates.
  int get id => 100 + weekday;

  @override
  bool operator ==(Object other) =>
      other is WeeklyReminder &&
      other.weekday == weekday &&
      other.hour == hour &&
      other.minute == minute &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(weekday, hour, minute, title, body);

  @override
  String toString() => 'WeeklyReminder($weekday $hour:$minute "$title" "$body")';
}

/// Schedules the daily reminder on the platform (ADR-023).
abstract interface class ReminderScheduler {
  /// Asks for permission to post notifications. Returns whether it is granted.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [reminders].
  /// [channelName] is the user-visible name of the Android channel.
  Future<void> schedule(List<WeeklyReminder> reminders, {required String channelName});

  /// Removes every scheduled reminder.
  Future<void> cancelAll();
}
