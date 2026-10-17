import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// The next moment at [hour]:[minute] on [weekday], strictly after [now].
tz.TZDateTime nextWeekly(tz.TZDateTime now, int weekday, int hour, int minute) {
  var date = tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
  while (date.weekday != weekday || !date.isAfter(now)) {
    date = tz.TZDateTime(now.location, date.year, date.month, date.day + 1, hour, minute);
  }
  return date;
}

/// [ReminderScheduler] backed by `flutter_local_notifications` (Android).
class LocalNotificationsScheduler implements ReminderScheduler {
  LocalNotificationsScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    // The full database includes legacy names (e.g. America/Montreal) that
    // some devices still report.
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
  }();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(List<WeeklyReminder> reminders, {required String channelName}) async {
    await _init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: nextWeekly(now, r.weekday, r.hour, r.minute),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(channelId, channelName),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }
}
