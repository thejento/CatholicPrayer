import 'dart:io';

import 'package:crc/src/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> pumpHome(WidgetTester tester, TestApp app) async {
  tester.view.physicalSize = const Size(400, 1600); // whole page
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
}

void main() {
  test('the default version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([^+\s]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  testWidgets('the web home ends with the version and the project links', (tester) async {
    final app = TestApp();
    await pumpHome(tester, app);
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('app-version'))).dy,
      greaterThan(tester.getTopLeft(find.text('Prayer Library')).dy),
    );
    await tester.tap(find.byKey(const Key('play-store-link')));
    await tester.tap(find.byKey(const Key('issues-link')));
    await tester.pumpAndSettle();
    expect(app.openedLinks, [playStoreUrl, issuesUrl]);
  });

  testWidgets('the footer is translated and says when a link fails', (tester) async {
    final app = TestApp(locale: const Locale('fr'))..linksOpen = false;
    await pumpHome(tester, app);
    expect(find.text('Signaler un problème sur GitHub'), findsOneWidget);
    await tester.tap(find.byKey(const Key('issues-link')));
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'ouvrir la page."), findsOneWidget);
  });

  testWidgets('the Android app has no footer', (tester) async {
    await pumpHome(tester, TestApp(isAndroid: true));
    expect(find.byKey(const Key('app-version')), findsNothing);
  });

  testWidgets('the footer is accessible', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, TestApp());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  Future<void> openSettings(WidgetTester tester, TestApp app) async {
    await pumpHome(tester, app);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('About and credits'));
    await tester.pumpAndSettle();
  }

  testWidgets('Settings has an About section with the version and GitHub', (tester) async {
    final app = TestApp(isAndroid: true);
    await openSettings(tester, app);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(find.byKey(const Key('settings-rate')), findsNothing); // not listed yet
    await tester.tap(find.byKey(const Key('settings-issues')));
    await tester.pumpAndSettle();
    expect(app.openedLinks, [issuesUrl]);
  });

  testWidgets('on TV Settings shows the GitHub address instead of a link', (tester) async {
    final app = TestApp(isAndroid: true, isTelevision: true);
    await openSettings(tester, app);
    expect(find.text(issuesUrl.toString()), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-issues')));
    await tester.pumpAndSettle();
    expect(app.openedLinks, isEmpty);
  });
}
