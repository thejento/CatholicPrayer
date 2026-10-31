import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, stepTitle;

Future<void> next(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.pumpAndSettle();
}

String guidance(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(const Key('step-guidance')), matching: find.byType(Text)),
    )
    .data!;

void main() {
  testWidgets('the Settings switches choose the ending', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app, size: const Size(400, 1600));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('End of the Rosary'), findsOneWidget);
    await tester.tap(find.byKey(const Key('end-holy-father')));
    await tester.pumpAndSettle();
    expect(app.settings.ending, const RosaryEnding(holyFather: true));
    await tester.tap(find.byKey(const Key('end-saint-michael')));
    await tester.pumpAndSettle();
    expect(app.settings.ending, RosaryEnding.all);
  });

  testWidgets("the guided Rosary ends with the Holy Father's intentions and Saint Michael", (
    tester,
  ) async {
    final app = TestApp();
    await app.settings.setEndWithHolyFather(true);
    await app.settings.setEndWithSaintMichael(true);
    // Resume on the closing prayer (step 79).
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.joyful, index: 78));
    await pumpApp(tester, app, size: const Size(400, 1200));

    expect(find.textContaining('Step 79 of 84'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue-rosary')));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Closing Prayer');

    await next(tester);
    expect(stepTitle(tester), 'Our Father');
    expect(guidance(tester), contains('intentions of the Holy Father'));
    await next(tester);
    expect(stepTitle(tester), 'Hail Mary');
    expect(guidance(tester), 'Then pray a Hail Mary for his intentions.');
    await next(tester);
    expect(stepTitle(tester), 'Glory Be');
    await next(tester);
    expect(stepTitle(tester), 'Prayer to Saint Michael the Archangel');
    expect(guidance(tester), 'Ask Saint Michael the Archangel to defend us.');
    expect(find.textContaining('Step 83 of 84'), findsOneWidget);
    await next(tester);
    expect(stepTitle(tester), 'Sign of the Cross');
  });

  testWidgets('mysteries only lists the extra prayers on the closing card', (tester) async {
    final app = TestApp();
    await app.settings.setEndWithSaintMichael(true);
    await app.savedSession.save(
      const SavedSession(mysterySet: MysterySet.joyful, index: 6, mode: RosaryMode.mysteriesOnly),
    );
    await pumpApp(tester, app, size: const Size(400, 1200));
    await tester.tap(find.byKey(const Key('continue-rosary')));
    await tester.pumpAndSettle();

    expect(stepTitle(tester), 'Closing prayers');
    expect(find.byKey(const Key('summary-saint_michael')), findsOneWidget);
    expect(find.byKey(const Key('summary-holy_father_intentions')), findsNothing);
  });

  testWidgets('Home and the Rosary agree on the step after the ending is turned off (r-14)', (
    tester,
  ) async {
    final app = TestApp();
    // Saved on Saint Michael (step 83 of 84), then the ending was turned off.
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.joyful, index: 82));
    await pumpApp(tester, app, size: const Size(400, 1200));

    expect(find.textContaining('Step 80 of 80'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue-rosary')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 80 of 80'), findsOneWidget);
    expect(stepTitle(tester), 'Sign of the Cross');
  });
}
