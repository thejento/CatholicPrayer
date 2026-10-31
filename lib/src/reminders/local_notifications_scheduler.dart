import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// A zone that is at [offset] from UTC at [at], for a device zone missing
/// from the time zone database (r-11); UTC if none is.
tz.Location locationForOffset(Duration offset, DateTime at) {
  final ms = at.millisecondsSinceEpoch;
  for (final location in tz.timeZoneDatabase.locations.values) {
    if (location.timeZone(ms).offset == offset) return location;
  }
  return tz.UTC;
}

/// [ReminderScheduler] backed by `flutter_local_notifications` (Android).
class LocalNotificationsScheduler implements ReminderScheduler {
  LocalNotificationsScheduler([FlutterLocalNotificationsPlugin? plugin, this._initialize])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin;

  /// Replaces the platform set-up in tests.
  final Future<void> Function()? _initialize;
  Future<void>? _ready;

  /// Sets up once; a failed set-up is tried again on the next call (r-11).
  @visibleForTesting
  Future<void> init() async {
    final ready = _ready ??= (_initialize ?? _setUp)();
    try {
      await ready;
    } catch (_) {
      if (identical(_ready, ready)) _ready = null;
      rethrow;
    }
  }

  Future<void> _setUp() async {
    // The full database includes legacy names (e.g. America/Montreal) that
    // some devices still report.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(await _localLocation());
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
  }

  static Future<tz.Location> _localLocation() async {
    try {
      return tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier);
    } catch (error) {
      // An unknown zone id (newer than the database) or a platform error.
      debugPrint('Reminder: local time zone unavailable ($error); using the UTC offset');
      final now = DateTime.now();
      return locationForOffset(now.timeZoneOffset, now);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    await init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(List<Reminder> reminders, {required String channelName}) async {
    await init();
    await _plugin.cancelAll();
    for (final r in reminders) {
      final at = r.at;
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(channelId, channelName),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
