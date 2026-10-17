import 'package:crc/src/reminders/local_notifications_scheduler.dart';
import 'package:crc/src/reminders/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  final montreal = tz.getLocation('America/Montreal');

  test('later the same day when the time has not passed', () {
    final now = tz.TZDateTime(montreal, 2026, 10, 12, 9); // Monday 09:00
    expect(nextWeekly(now, DateTime.monday, 20, 0), tz.TZDateTime(montreal, 2026, 10, 12, 20));
  });

  test('next week when the time has passed today', () {
    final now = tz.TZDateTime(montreal, 2026, 10, 12, 21);
    expect(nextWeekly(now, DateTime.monday, 20, 0), tz.TZDateTime(montreal, 2026, 10, 19, 20));
  });

  test('the coming weekday, keeping wall-clock time across a DST change', () {
    // Clocks go back on Sunday 1 November 2026 in Montreal.
    final now = tz.TZDateTime(montreal, 2026, 10, 30, 12); // Friday
    final next = nextWeekly(now, DateTime.monday, 20, 0);
    expect(next, tz.TZDateTime(montreal, 2026, 11, 2, 20));
    expect(next.hour, 20);
  });

  test('ids are stable per weekday', () {
    const r = WeeklyReminder(weekday: 3, hour: 1, minute: 2, title: 't', body: 'b');
    expect(r.id, 103);
    expect(r, const WeeklyReminder(weekday: 3, hour: 1, minute: 2, title: 't', body: 'b'));
    expect(r.toString(), contains('3 1:2'));
  });
}
