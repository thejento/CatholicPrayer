import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, startRosary, stepTitle;

void main() {
  testWidgets('the library tells where a prayer comes from', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(400, 1200));
    await tester.tap(find.text('Prayer Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hail Mary'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-prayer')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'About this prayer'), findsOneWidget);
    expect(find.text('Where it comes from'), findsOneWidget);
    expect(find.textContaining('angel Gabriel'), findsOneWidget);
    expect(find.text('When it is prayed'), findsOneWidget);
    expect(find.text('In Scripture'), findsOneWidget);
    expect(find.text('Luke 1:28; Luke 1:42'), findsOneWidget);
  });

  testWidgets('a prayer without Scripture roots has no Scripture section', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(400, 1200));
    await tester.tap(find.text('Prayer Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memorare'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-prayer')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Claude Bernard'), findsOneWidget);
    expect(find.text('In Scripture'), findsNothing);
  });

  testWidgets('the guided Rosary offers it under the prayer', (tester) async {
    await pumpApp(tester, TestApp());
    await startRosary(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // the Creed
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('about-prayer')));
    await tester.tap(find.byKey(const Key('about-prayer')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Old Roman Creed'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(stepTitle(tester), "Apostles' Creed");
  });

  testWidgets('it is translated', (tester) async {
    await pumpApp(tester, TestApp(locale: const Locale('fr')), size: const Size(400, 1200));
    await tester.tap(find.text('Bibliothèque de prières'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notre Père'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-prayer')));
    await tester.pumpAndSettle();
    expect(find.text("D'où elle vient"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Matthieu 6,9-13 ; Luc 11,1-4'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Matthieu 6,9-13 ; Luc 11,1-4'), findsOneWidget);
  });

  testWidgets('on TV the D-pad walks through the sections', (tester) async {
    await pumpApp(tester, TestApp(isTelevision: true), size: const Size(960, 540));
    await tester.ensureVisible(find.text('Prayer Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prayer Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign of the Cross'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-prayer')));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.byKey(const Key('note-0')))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.byKey(const Key('note-1')))).hasFocus, isTrue);
  });
}
