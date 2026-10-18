import 'dart:io';

import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> announce(WidgetTester tester, TestApp app, {Size size = const Size(400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
  for (final button in [find.byType(FilledButton).first, find.byType(FilledButton).last]) {
    // Pray the Rosary, then Start.
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 7; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  }
  await tester.pumpAndSettle();
}

final card = find.byKey(const Key('mystery-artwork'), skipOffstage: false);

void main() {
  test('every mystery has a public-domain painting that ships with the app', () {
    final art = loadRealArt();
    for (final set in MysterySet.values) {
      for (var decade = 1; decade <= mysteriesPerSet; decade++) {
        final a = art.artwork(set, decade);
        expect(a, isNotNull, reason: '$set $decade');
        expect(File(a!.file).existsSync(), isTrue, reason: a.file);
        expect(a.license, anyOf('CC0', startsWith('Public domain')), reason: a.title);
        expect([a.title, a.artist, a.museum, a.page], everyElement(isNotEmpty));
        expect(a.aspectRatio, inInclusiveRange(0.3, 3));
      }
    }
    expect(art.all, hasLength(20));
  });

  testWidgets('the classic theme shows the painting of the announced mystery', (tester) async {
    final handle = tester.ensureSemantics();
    await announce(tester, TestApp());
    expect(card, findsOneWidget);
    expect(
      find.bySemanticsLabel('Painting: The Annunciation, by Masolino da Panicale'),
      findsOneWidget,
    );
    expect(find.textContaining('National Gallery of Art, Washington (CC0)'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no painting on prayer steps', (tester) async {
    await announce(tester, TestApp());
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // Our Father
    await tester.pumpAndSettle();
    expect(card, findsNothing);
  });

  testWidgets('the kid-friendly theme never shows paintings', (tester) async {
    final app = TestApp();
    await app.themeManager.setMode(AppThemeMode.kidFriendly);
    await announce(tester, app);
    expect(card, findsNothing);
    expect(find.byKey(const Key('step-title')), findsOneWidget);
  });

  testWidgets('a tall painting fits on a small phone at 200 % text and on TV', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await announce(tester, TestApp(), size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    // The painting keeps to about a quarter of the screen; the caption may wrap.
    final painting = find.descendant(of: card, matching: find.byType(Image), skipOffstage: false);
    expect(tester.getSize(painting).height, lessThanOrEqualTo(640 * 0.26 + 0.5));
    await announce(tester, TestApp(isTelevision: true), size: const Size(960, 540));
    expect(tester.takeException(), isNull);
  });
}
