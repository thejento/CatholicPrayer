import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/domain/clock.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/reminders/reminder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_reminder_scheduler.dart';

const texts = ReminderTexts(
  title: 'Pray',
  channelName: 'Daily reminder',
  bodies: {
    MysterySet.joyful: 'joyful',
    MysterySet.luminous: 'luminous',
    MysterySet.sorrowful: 'sorrowful',
    MysterySet.glorious: 'glorious',
  },
);

/// Monday 12 October 2026, 09:00.
final monday = DateTime(2026, 10, 12, 9);

void main() {
  late InMemoryPreferencesStore store;
  late FakeReminderScheduler scheduler;
  ReminderController controller({bool available = true, DateTime? now}) =>
      ReminderController(store, scheduler, available: available, clock: Clock.fixed(now ?? monday));

  setUp(() {
    store = InMemoryPreferencesStore();
    scheduler = FakeReminderScheduler();
  });

  test('is off at 20:00 by default', () async {
    final c = controller();
    await c.load();
    expect(c.enabled, isFalse);
    expect(c.time, const TimeOfDay(hour: 20, minute: 0));
  });

  test(
    'turning on asks permission and schedules one reminder a day, naming its mysteries',
    () async {
      final c = controller();
      await c.updateTexts(texts);
      expect(await c.setEnabled(true), ReminderChange.done);

      expect(scheduler.permissionRequests, 1);
      expect(scheduler.channelName, 'Daily reminder');
      final scheduled = scheduler.scheduled;
      expect(scheduled, hasLength(ReminderController.daysAhead));
      expect(scheduled.first.at, DateTime(2026, 10, 12, 20), reason: 'today, as 20:00 is ahead');
      expect(scheduled.map((r) => r.id).toSet(), hasLength(ReminderController.daysAhead));
      expect(scheduled.take(7).map((r) => r.body), [
        'joyful', // Monday
        'sorrowful',
        'glorious',
        'luminous',
        'sorrowful',
        'joyful',
        'glorious', // Sunday in Ordinary Time
      ]);
      expect(scheduled.every((r) => r.at.hour == 20 && r.title == 'Pray'), isTrue);
    },
  );

  test('starts tomorrow when the time has passed today', () async {
    final c = controller(now: DateTime(2026, 10, 12, 21));
    await c.updateTexts(texts);
    await c.setEnabled(true);
    expect(scheduler.scheduled.first.at, DateTime(2026, 10, 13, 20));
  });

  test('Sundays follow the season weeks ahead: Advent names the Joyful Mysteries (r-12)', () async {
    // Friday 20 November 2026; Advent begins on Sunday 29 November.
    final c = controller(now: DateTime(2026, 11, 20, 9));
    await c.updateTexts(texts);
    await c.setEnabled(true);
    String on(DateTime day) =>
        scheduler.scheduled.firstWhere((r) => DateUtils.isSameDay(r.at, day)).body;
    expect(on(DateTime(2026, 11, 22)), 'glorious');
    expect(on(DateTime(2026, 11, 29)), 'joyful');

    // Lent 2027 begins on Ash Wednesday, 10 February.
    final lent = controller(now: DateTime(2027, 2, 1, 9));
    await lent.updateTexts(texts);
    await lent.setEnabled(true);
    expect(on(DateTime(2027, 2, 7)), 'glorious');
    expect(on(DateTime(2027, 2, 14)), 'sorrowful');
  });

  test('a refused permission keeps it off and saves nothing', () async {
    scheduler.deny = true;
    final c = controller();
    await c.updateTexts(texts);
    expect(await c.setEnabled(true), ReminderChange.denied);
    expect(c.enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(await store.getBool(ReminderController.enabledKey), isNull);
  });

  test('a scheduling failure turns it back off without throwing (r-11)', () async {
    final c = controller();
    await c.updateTexts(texts);
    scheduler.failWith = Exception('unknown time zone');
    expect(await c.setEnabled(true), ReminderChange.failed);
    expect(c.enabled, isFalse);
    expect(await store.getBool(ReminderController.enabledKey), isFalse);

    // Once the platform works again, it can be turned on.
    scheduler.failWith = null;
    expect(await c.setEnabled(true), ReminderChange.done);
    expect(scheduler.scheduled, isNotEmpty);
  });

  test('a failure at start-up is retried with the next texts', () async {
    await store.setBool(ReminderController.enabledKey, true);
    scheduler.failWith = Exception('not ready');
    final c = controller();
    await c.load();
    await c.updateTexts(texts);
    expect(scheduler.scheduled, isEmpty);

    scheduler.failWith = null;
    await c.updateTexts(texts);
    expect(scheduler.scheduled, hasLength(ReminderController.daysAhead));
  });

  test('changing the time reschedules, turning off cancels', () async {
    final c = controller();
    await c.updateTexts(texts);
    await c.setEnabled(true);
    await c.setTime(const TimeOfDay(hour: 7, minute: 30));
    expect(scheduler.scheduled.every((r) => r.at.hour == 7 && r.at.minute == 30), isTrue);
    expect(scheduler.scheduled.first.at, DateTime(2026, 10, 13, 7, 30));

    expect(await c.setEnabled(false), ReminderChange.done);
    expect(scheduler.scheduled, isEmpty);
  });

  test('new texts (a language change) reschedule', () async {
    final c = controller();
    await c.updateTexts(texts);
    await c.setEnabled(true);
    await c.updateTexts(
      const ReminderTexts(
        title: 'Priez',
        channelName: 'Rappel',
        bodies: {
          MysterySet.joyful: 'joyeux',
          MysterySet.luminous: 'lumineux',
          MysterySet.sorrowful: 'douloureux',
          MysterySet.glorious: 'glorieux',
        },
      ),
    );
    expect(scheduler.scheduled.first.title, 'Priez');
    expect(scheduler.scheduled.first.body, 'joyeux');
    expect(scheduler.channelName, 'Rappel');
  });

  test('the setting survives a restart and is rescheduled', () async {
    final first = controller();
    await first.updateTexts(texts);
    await first.setEnabled(true);
    await first.setTime(const TimeOfDay(hour: 6, minute: 5));

    scheduler = FakeReminderScheduler();
    final second = controller();
    await second.load();
    expect(second.enabled, isTrue);
    expect(second.time, const TimeOfDay(hour: 6, minute: 5));
    await second.updateTexts(texts);
    expect(scheduler.scheduled, hasLength(ReminderController.daysAhead));
    expect(scheduler.permissionRequests, 0);
  });

  test('ignores a corrupt saved time', () async {
    await store.setString(ReminderController.timeKey, '99999');
    final c = controller();
    await c.load();
    expect(c.time, ReminderController.defaultTime);
  });

  test('never schedules where reminders are not offered', () async {
    final c = controller(available: false);
    await c.updateTexts(texts);
    await c.setEnabled(true);
    expect(scheduler.scheduled, isEmpty);
  });

  test('texts compare by value', () {
    expect(
      texts,
      ReminderTexts(title: 'Pray', channelName: 'Daily reminder', bodies: {...texts.bodies}),
    );
    expect(
      texts.hashCode,
      ReminderTexts(
        title: 'Pray',
        channelName: 'Daily reminder',
        bodies: {...texts.bodies},
      ).hashCode,
    );
  });
}
