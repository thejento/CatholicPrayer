import 'package:crc/src/reminders/reminder_scheduler.dart';

/// Records what would be scheduled; permission is granted unless [deny].
class FakeReminderScheduler implements ReminderScheduler {
  bool deny = false;
  int permissionRequests = 0;
  List<WeeklyReminder> scheduled = [];
  String? channelName;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return !deny;
  }

  @override
  Future<void> schedule(List<WeeklyReminder> reminders, {required String channelName}) async {
    scheduled = List.of(reminders);
    this.channelName = channelName;
  }

  @override
  Future<void> cancelAll() async => scheduled = [];
}
