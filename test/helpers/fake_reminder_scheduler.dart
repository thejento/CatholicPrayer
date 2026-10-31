import 'package:crc/src/reminders/reminder_scheduler.dart';

/// Records what would be scheduled; permission is granted unless [deny].
class FakeReminderScheduler implements ReminderScheduler {
  bool deny = false;

  /// When set, [schedule] and [cancelAll] fail with it.
  Object? failWith;
  int permissionRequests = 0;
  List<Reminder> scheduled = [];
  String? channelName;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return !deny;
  }

  @override
  Future<void> schedule(List<Reminder> reminders, {required String channelName}) async {
    if (failWith case final error?) throw error;
    scheduled = List.of(reminders);
    this.channelName = channelName;
  }

  @override
  Future<void> cancelAll() async {
    if (failWith case final error?) throw error;
    scheduled = [];
  }
}
