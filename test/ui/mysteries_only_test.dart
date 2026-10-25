import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/providers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, stepTitle;

Future<void> startMysteriesOnly(WidgetTester tester) async {
  await tester.tap(find.text('Pray the Rosary'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mysteries only'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
}

Future<void> next(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the picker offers the mode, explains it and remembers it', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app);
    await tester.tap(find.text('Pray the Rosary'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('rosary-mode-hint'))).data,
      startsWith('Every prayer, bead by bead'),
    );
    await tester.tap(find.text('Mysteries only'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('rosary-mode-hint'))).data,
      startsWith('For those who know the prayers'),
    );
    expect(app.settings.rosaryMode, RosaryMode.mysteriesOnly);
    expect(await app.store.getString(SettingsController.rosaryModeKey), 'mysteriesOnly');
  });

  testWidgets('seven steps: opening prayers, five mysteries, closing prayers', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(400, 1000));
    await startMysteriesOnly(tester);

    expect(stepTitle(tester), 'Opening prayers');
    expect(find.text('Introduction · Step 1 of 7'), findsOneWidget);
    expect(find.text('Hail Mary × 3'), findsOneWidget);
    expect(find.byKey(const Key('step-guidance')), findsNothing);

    await next(tester);
    expect(stepTitle(tester), 'The Annunciation');
    expect(find.byKey(const Key('pray-the-decade')), findsOneWidget);
    expect(find.byKey(const Key('step-guidance')), findsNothing);

    for (final title in [
      'The Visitation',
      'The Nativity',
      'The Presentation in the Temple',
      'The Finding of Jesus in the Temple',
      'Closing prayers',
    ]) {
      await next(tester);
      expect(stepTitle(tester), title);
    }
    expect(find.text('Hail, Holy Queen'), findsOneWidget);
    await next(tester);
    expect(find.byKey(const Key('step-title')), findsNothing); // completion
  });

  testWidgets('a prayer on a summary card opens its words', (tester) async {
    await pumpApp(tester, TestApp());
    await startMysteriesOnly(tester);
    await tester.tap(find.byKey(const Key('summary-apostles_creed')));
    await tester.pumpAndSettle();
    expect(find.textContaining('I believe in God'), findsOneWidget);
  });

  testWidgets('the voice has no auto-advance here', (tester) async {
    final app = TestApp();
    await app.settings.setVoiceEnabled(true);
    await pumpApp(tester, app);
    await startMysteriesOnly(tester);
    expect(find.byKey(const Key('voice-speed')), findsOneWidget);
    expect(find.byKey(const Key('auto-advance')), findsNothing);
    await next(tester);
    expect(app.player.last, ['assets/audio/en/mystery_joyful_1.mp3']);
  });

  testWidgets('an unfinished Rosary resumes in the same mode', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app);
    await startMysteriesOnly(tester);
    await next(tester);
    await next(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Joyful Mysteries · Mysteries only · Step 3 of 7'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue-rosary')));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'The Visitation');
  });
}
