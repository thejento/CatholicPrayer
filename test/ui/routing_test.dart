import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:crc/src/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, stepTitle;

/// Opens the app at [location], as a link or a browser refresh would.
Future<void> openAt(WidgetTester tester, TestApp app, String location) async {
  tester.binding.platformDispatcher.defaultRouteNameTestValue = location;
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
  await pumpApp(tester, app, size: const Size(400, 1000));
}

/// The address the browser shows.
String address(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).last)).routeInformationProvider.value.uri
        .toString();

String appBarTitle(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byType(AppBar).last, matching: find.byType(Text)).first)
    .data!;

void main() {
  test('addresses', () {
    expect(Routes.rosary(MysterySet.joyful, RosaryMode.guided), '/rosary/joyful');
    expect(
      Routes.rosary(MysterySet.glorious, RosaryMode.mysteriesOnly),
      '/rosary/glorious?mode=mysteriesOnly',
    );
    expect(
      Routes.passage(MysterySet.sorrowful, RosaryMode.guided, 2),
      '/rosary/sorrowful/passage/2',
    );
    expect(Routes.aboutPrayer('memorare'), '/library/memorare/about');
  });

  testWidgets('the address follows the screens', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(400, 1000));
    expect(address(tester), '/');
    await tester.tap(find.text('Prayer Library'));
    await tester.pumpAndSettle();
    expect(address(tester), '/library');
    await tester.tap(find.text('Hail Mary'));
    await tester.pumpAndSettle();
    expect(address(tester), '/library/hail_mary');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(address(tester), '/library');
  });

  testWidgets('a link opens a prayer, and Back climbs to Home', (tester) async {
    await openAt(tester, TestApp(), '/library/memorare');
    expect(appBarTitle(tester), 'Memorare');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(appBarTitle(tester), 'Prayer Library');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Pray the Rosary'), findsOneWidget);
  });

  testWidgets('a link opens the background of a prayer', (tester) async {
    await openAt(tester, TestApp(), '/library/hail_mary/about');
    expect(find.byKey(const Key('note-0')), findsOneWidget);
  });

  testWidgets('an unknown prayer opens the library; an unknown address, Home', (tester) async {
    await openAt(tester, TestApp(), '/library/nope');
    expect(address(tester), '/library');
    expect(appBarTitle(tester), 'Prayer Library');
  });

  testWidgets('an unknown address opens Home', (tester) async {
    await openAt(tester, TestApp(), '/nowhere');
    expect(find.text('Pray the Rosary'), findsOneWidget);
  });

  for (final (location, title) in [
    ('/settings', 'Settings'),
    ('/pray', 'Choose the mysteries'),
    ('/journal', 'Prayer journal'),
    ('/chaplet/divine-mercy', 'Divine Mercy Chaplet'),
  ]) {
    testWidgets('$location opens $title', (tester) async {
      await openAt(tester, TestApp(), location);
      expect(appBarTitle(tester), title);
    });
  }

  testWidgets('/today opens About today', (tester) async {
    await openAt(tester, TestApp(), '/today');
    expect(address(tester), '/today');
    expect(find.text('Pray the Rosary'), findsNothing);
  });

  testWidgets('a refresh during a Rosary resumes the saved step', (tester) async {
    final app = TestApp();
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.sorrowful, index: 20));
    await openAt(tester, app, '/rosary/sorrowful');
    expect(find.textContaining('Step 21 of 80'), findsOneWidget);
  });

  testWidgets('a link to another Rosary starts at the beginning', (tester) async {
    final app = TestApp();
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.sorrowful, index: 20));
    await openAt(tester, app, '/rosary/glorious?mode=mysteriesOnly');
    expect(find.textContaining('Step 1 of 7'), findsOneWidget);
  });

  testWidgets('an unknown mystery set opens the picker', (tester) async {
    await openAt(tester, TestApp(), '/rosary/cheerful');
    expect(address(tester), '/pray');
  });

  testWidgets('starting from the picker begins again, even with a saved Rosary', (tester) async {
    final app = TestApp();
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.joyful, index: 20));
    await pumpApp(tester, app, size: const Size(400, 1000));
    await tester.tap(find.text('Pray the Rosary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(address(tester), '/rosary/joyful');
    expect(stepTitle(tester), 'Sign of the Cross');
  });

  testWidgets('a passage opens over its Rosary; Back returns to it', (tester) async {
    final app = TestApp();
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.joyful, index: 21));
    await openAt(tester, app, '/rosary/joyful/passage/2');
    expect(find.textContaining('Luke 1'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'The Visitation');
    expect(address(tester), '/rosary/joyful');
  });

  testWidgets('a passage number out of range opens the Rosary', (tester) async {
    await openAt(tester, TestApp(), '/rosary/joyful/passage/9');
    expect(address(tester), '/rosary/joyful');
  });
}
