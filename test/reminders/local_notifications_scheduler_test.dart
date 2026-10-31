import 'package:crc/src/reminders/local_notifications_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();

  group('locationForOffset (r-11)', () {
    final at = DateTime.utc(2026, 7, 1, 12);

    test('finds a zone at that offset, for an id the database lacks', () {
      for (final hours in [-7, -4, 0, 2, 9]) {
        final offset = Duration(hours: hours);
        final location = locationForOffset(offset, at);
        expect(location.timeZone(at.millisecondsSinceEpoch).offset, offset);
      }
    });

    test('handles half-hour zones, and falls back to UTC when none match', () {
      final india = locationForOffset(const Duration(hours: 5, minutes: 30), at);
      expect(
        india.timeZone(at.millisecondsSinceEpoch).offset,
        const Duration(hours: 5, minutes: 30),
      );
      expect(locationForOffset(const Duration(hours: 5, minutes: 17), at), tz.UTC);
    });
  });

  test('a failed set-up is tried again on the next call (r-11)', () async {
    var attempts = 0;
    final scheduler = LocalNotificationsScheduler(null, () async {
      attempts++;
      if (attempts == 1) throw Exception('timezone');
    });
    await expectLater(scheduler.init(), throwsException);
    await scheduler.init();
    await scheduler.init();
    expect(attempts, 2);
  });
}
