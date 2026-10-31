import 'package:flutter/foundation.dart';

/// One notification on a given day, at wall-clock time [at] (local).
@immutable
class Reminder {
  const Reminder({required this.id, required this.at, required this.title, required this.body});

  /// Stable per position, so rescheduling replaces rather than duplicates.
  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, at, title, body);

  @override
  String toString() => 'Reminder($id $at "$title" "$body")';
}

/// Schedules the daily reminder on the platform (ADR-023).
abstract interface class ReminderScheduler {
  /// Asks for permission to post notifications. Returns whether it is granted.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [reminders].
  /// [channelName] is the user-visible name of the Android channel.
  Future<void> schedule(List<Reminder> reminders, {required String channelName});

  /// Removes every scheduled reminder.
  Future<void> cancelAll();
}
