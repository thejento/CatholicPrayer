import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, stepTitle;

Future<void> next(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  }
  await tester.pumpAndSettle();
}

String guidance(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(const Key('step-guidance')), matching: find.byType(Text)),
    )
    .data!;

void main() {
  testWidgets('Home opens the Divine Mercy Chaplet, bead by bead', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(400, 1000));
    await tester.tap(find.byKey(const Key('divine-mercy')));
    await tester.pumpAndSettle();

    expect(find.text('Divine Mercy Chaplet'), findsOneWidget, reason: 'app bar');
    expect(stepTitle(tester), 'Sign of the Cross');
    expect(find.textContaining('Step 1 of 63'), findsOneWidget);

    await next(tester, 2);
    expect(stepTitle(tester), 'Hail Mary');
    expect(guidance(tester), 'On the next bead, pray the Hail Mary.');
    await next(tester, 2);
    expect(stepTitle(tester), 'Eternal Father (Divine Mercy Chaplet)');
    expect(find.textContaining('Body and Blood, Soul and Divinity'), findsOneWidget);
    await next(tester);
    expect(stepTitle(tester), 'For the Sake of His Sorrowful Passion (1 of 10)');
    expect(find.textContaining('Decade 1'), findsOneWidget);

    await next(tester, 54);
    expect(stepTitle(tester), 'Holy God (1 of 3)');
    await next(tester, 3);
    expect(stepTitle(tester), 'Sign of the Cross');
    await next(tester);
    expect(find.text('You prayed the Divine Mercy Chaplet!'), findsOneWidget);
    expect(find.textContaining('Jesus, I trust in you.'), findsOneWidget);
  });

  testWidgets("the chaplet leaves an unfinished Rosary's progress alone", (tester) async {
    final app = TestApp();
    const saved = SavedSession(mysterySet: MysterySet.sorrowful, index: 30);
    await app.savedSession.save(saved);
    await pumpApp(tester, app, size: const Size(400, 1000));
    await tester.tap(find.byKey(const Key('divine-mercy')));
    await tester.pumpAndSettle();
    await next(tester, 63);
    expect(app.savedSession.saved, saved);
  });

  testWidgets('the chaplet speaks French', (tester) async {
    final app = TestApp(locale: const Locale('fr'));
    await pumpApp(tester, app, size: const Size(400, 1000));
    await tester.tap(find.byKey(const Key('divine-mercy')));
    await tester.pumpAndSettle();
    expect(find.text('Chapelet de la Divine Miséricorde'), findsOneWidget);
    await next(tester, 59);
    expect(stepTitle(tester), 'Dieu saint (1 sur 3)');
  });
}
