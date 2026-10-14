import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:crc/src/ui/widgets/rosary_beads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, startRosary, stepTitle;

void main() {
  group('resume (F-06)', () {
    testWidgets('leaving mid-Rosary offers to continue at the same step', (tester) async {
      final app = TestApp();
      await pumpApp(tester, app);
      expect(find.byKey(const Key('continue-rosary')), findsNothing);

      await startRosary(tester);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pumpAndSettle();
      expect(app.savedSession.saved, const SavedSession(mysterySet: MysterySet.joyful, index: 3));

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 4 of 80'), findsOneWidget);

      await tester.tap(find.byKey(const Key('continue-rosary')));
      await tester.pumpAndSettle();
      expect(stepTitle(tester), 'Hail Mary (1 of 3)');
    });

    testWidgets('finishing the Rosary forgets the saved step', (tester) async {
      final app = TestApp();
      await app.savedSession.save(const SavedSession(mysterySet: MysterySet.glorious, index: 78));
      await pumpApp(tester, app);
      await tester.tap(find.byKey(const Key('continue-rosary')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Glorious Mysteries'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('You prayed the Rosary!'), findsOneWidget);
      expect(app.savedSession.saved, isNull);
    });
  });

  testWidgets('the glow travels from the previous bead (F-07)', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(1000, 700));
    await startRosary(tester);
    RosaryPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(of: find.byType(RosaryBeads), matching: find.byType(CustomPaint)),
                )
                .painter!
            as RosaryPainter;

    // Creed (crucifix) → Our Father (bead 1).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(RosaryBeads.moveDuration ~/ 2);
    expect(painter().from, 0);
    expect(painter().current, 1);
    expect(painter().move, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(painter().move, 1);
  });

  group('Android TV (T-04)', () {
    testWidgets('uses the side-by-side layout and 10-foot type scale', (tester) async {
      await pumpApp(tester, TestApp(isTelevision: true), size: const Size(960, 540));
      await startRosary(tester);
      final title = find.byKey(const Key('step-title'));
      expect(MediaQuery.textScalerOf(tester.element(title)).scale(10), closeTo(13, 0.01));
      final beads = tester.getRect(find.byType(RosaryBeads));
      expect(beads.right, lessThan(tester.getRect(title).left));
    });

    testWidgets('a phone of the same size keeps normal text', (tester) async {
      await pumpApp(tester, TestApp(), size: const Size(960, 540));
      await startRosary(tester);
      final title = find.byKey(const Key('step-title'));
      expect(MediaQuery.textScalerOf(tester.element(title)).scale(10), 10);
    });
  });
}
