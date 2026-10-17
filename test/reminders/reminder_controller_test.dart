import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/reminders/reminder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_reminder_scheduler.dart';

const texts = ReminderTexts(
  title: 'Pray',
  channelName: 'Daily reminder',
  bodies: {1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat', 7: 'sun'},
);

void main() {
  late InMemoryPreferencesStore store;
  late FakeReminderScheduler scheduler;
  ReminderController controller({bool available = true}) =>
      ReminderController(store, scheduler, available: available);

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

  test('turning on asks permission and schedules one reminder per weekday', () async {
    final c = controller();
    await c.updateTexts(texts);
    expect(await c.setEnabled(true), isTrue);

    expect(scheduler.permissionRequests, 1);
    expect(scheduler.channelName, 'Daily reminder');
    expect(scheduler.scheduled.map((r) => r.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(scheduler.scheduled.map((r) => r.body), texts.bodies.values);
    expect(scheduler.scheduled.map((r) => r.id).toSet(), hasLength(7));
    expect(
      scheduler.scheduled.every((r) => r.hour == 20 && r.minute == 0 && r.title == 'Pray'),
      isTrue,
    );
  });

  test('a refused permission keeps it off and saves nothing', () async {
    scheduler.deny = true;
    final c = controller();
    await c.updateTexts(texts);
    expect(await c.setEnabled(true), isFalse);
    expect(c.enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(await store.getBool(ReminderController.enabledKey), isNull);
  });

  test('changing the time reschedules, turning off cancels', () async {
    final c = controller();
    await c.updateTexts(texts);
    await c.setEnabled(true);
    await c.setTime(const TimeOfDay(hour: 7, minute: 30));
    expect(scheduler.scheduled.every((r) => r.hour == 7 && r.minute == 30), isTrue);

    await c.setEnabled(false);
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
        bodies: {1: 'lun', 2: 'mar', 3: 'mer', 4: 'jeu', 5: 'ven', 6: 'sam', 7: 'dim'},
      ),
    );
    expect(scheduler.scheduled.first.title, 'Priez');
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
    expect(scheduler.scheduled, hasLength(7));
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
      const ReminderTexts(
        title: 'Pray',
        channelName: 'Daily reminder',
        bodies: {1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat', 7: 'sun'},
      ),
    );
    expect(texts.hashCode, isA<int>());
  });
}
