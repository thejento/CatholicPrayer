import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> openSettings(WidgetTester tester, TestApp app) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

final reminderSwitch = find.byKey(const Key('reminder-switch'));

void main() {
  testWidgets('not offered on the web or on a TV', (tester) async {
    await openSettings(tester, TestApp());
    expect(reminderSwitch, findsNothing);
  });

  testWidgets('not offered on Android TV', (tester) async {
    await openSettings(tester, TestApp(isAndroid: true, isTelevision: true));
    expect(reminderSwitch, findsNothing);
  });

  testWidgets('turning it on schedules a reminder naming each day\'s mysteries', (tester) async {
    final app = TestApp(isAndroid: true);
    await openSettings(tester, app);
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('8:00 PM'), findsOneWidget);

    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();
    final byDay = {for (final r in app.reminders.scheduled) r.weekday: r};
    expect(byDay, hasLength(7));
    expect(byDay[DateTime.monday]!.title, 'Time to pray the Rosary');
    expect(byDay[DateTime.monday]!.body, 'Today: the Joyful Mysteries.');
    expect(byDay[DateTime.tuesday]!.body, 'Today: the Sorrowful Mysteries.');
    expect(byDay[DateTime.thursday]!.body, 'Today: the Luminous Mysteries.');
    expect(byDay[DateTime.sunday]!.body, 'Today: the Glorious Mysteries.');
  });

  testWidgets('a refused permission explains how to allow it', (tester) async {
    final app = TestApp(isAndroid: true)..reminders.deny = true;
    await openSettings(tester, app);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();
    expect(find.textContaining('Allow them in Android settings'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(reminderSwitch).value, isFalse);
  });

  testWidgets('the time can be changed with the time picker', (tester) async {
    final app = TestApp(isAndroid: true);
    await openSettings(tester, app);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-time')));
    await tester.pumpAndSettle();
    // Switch the dial to text entry and type 07:15 AM.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '7');
    await tester.enterText(fields.at(1), '15');
    await tester.tap(find.text('AM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('7:15 AM'), findsOneWidget);
    expect(app.reminders.scheduled.every((r) => r.hour == 7 && r.minute == 15), isTrue);
  });

  testWidgets('switching language reschedules in that language', (tester) async {
    final app = TestApp(isAndroid: true);
    await openSettings(tester, app);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    await app.settings.setLocale(const Locale('fr'));
    await tester.pumpAndSettle();
    final monday = app.reminders.scheduled.firstWhere((r) => r.weekday == DateTime.monday);
    expect(monday.title, "C'est l'heure du chapelet");
    expect(monday.body, "Aujourd'hui : les Mystères joyeux.");
    expect(app.reminders.channelName, 'Rappel quotidien');
  });

  testWidgets('the reminder settings meet accessibility guidelines, also at 200 % text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = TestApp(isAndroid: true);
    await openSettings(tester, app);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('reminder-time')), 200);
    expect(tester.takeException(), isNull);
  });
}
