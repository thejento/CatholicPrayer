import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> openAnnunciation(
  WidgetTester tester,
  TestApp app, {
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FilledButton).first); // Pray the Rosary
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FilledButton).last); // Start
  await tester.pumpAndSettle();
  for (var i = 0; i < 7; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the mystery announcement opens its Bible passage', (tester) async {
    await openAnnunciation(tester, TestApp());
    await tester.ensureVisible(find.byKey(const Key('read-passage')));
    await tester.tap(find.byKey(const Key('read-passage')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'The Annunciation'), findsOneWidget);
    expect(find.byKey(const Key('passage-reference')), findsOneWidget);
    expect(find.text('Luke 1:26-38'), findsOneWidget);
    expect(find.textContaining('full of grace', findRichText: true), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Douay-Rheims'), 300);
    expect(find.textContaining('Public domain'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('read-passage')), findsOneWidget);
  });

  testWidgets('the passage follows the app language', (tester) async {
    await openAnnunciation(tester, TestApp(locale: const Locale('es')));
    await tester.ensureVisible(find.byKey(const Key('read-passage')));
    await tester.tap(find.text('Leer el pasaje'));
    await tester.pumpAndSettle();
    expect(find.text('Lucas 1,26-38'), findsOneWidget);
    expect(find.textContaining('llena de gracia', findRichText: true), findsOneWidget);
  });

  testWidgets('on TV the D-pad moves through the verses', (tester) async {
    await openAnnunciation(tester, TestApp(isTelevision: true), size: const Size(960, 540));
    await tester.ensureVisible(find.byKey(const Key('read-passage')));
    await tester.tap(find.byKey(const Key('read-passage')));
    await tester.pumpAndSettle();

    bool focused(int verse) => Focus.of(tester.element(find.byKey(Key('verse-$verse')))).hasFocus;
    expect(focused(26), isTrue);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(focused(38), isTrue);
    expect(tester.getRect(find.byKey(const Key('verse-38'))).bottom, lessThanOrEqualTo(540));
  });
}
