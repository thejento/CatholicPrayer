import 'package:crc/src/audio/audio_catalog.dart';
import 'package:crc/src/providers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, startRosary, stepTitle;

void main() {
  testWidgets('the speaker button reads the step aloud and remembers it', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app);
    await startRosary(tester);
    expect(app.player.played, isEmpty);

    await tester.tap(find.byKey(const Key('voice-toggle')));
    await tester.pumpAndSettle();
    expect(app.player.last, [
      'assets/audio/en/guide_signOfCrossStart.mp3',
      'assets/audio/en/prayer_sign_of_the_cross.mp3',
    ]);
    expect(app.settings.voiceEnabled, isTrue);
    expect(find.byTooltip('Stop reading aloud'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voice-toggle')));
    await tester.pumpAndSettle();
    expect(app.player.isPlaying, isFalse);
    expect(app.settings.voiceEnabled, isFalse);
  });

  testWidgets('speed can be slowed down and sped up a bit', (tester) async {
    final app = TestApp();
    await app.settings.setVoiceEnabled(true);
    await pumpApp(tester, app);
    await startRosary(tester);
    String speed() => tester.widget<Text>(find.byKey(const Key('voice-speed'))).data!;
    expect(speed(), '1.0×');

    await tester.tap(find.byKey(const Key('voice-slower')));
    await tester.pumpAndSettle();
    expect(speed(), '0.85×');
    await tester.tap(find.byKey(const Key('voice-slower')));
    await tester.pumpAndSettle();
    expect(speed(), '0.75×');
    expect(
      tester.widget<IconButton>(find.byKey(const Key('voice-slower'))).onPressed,
      isNull,
      reason: 'slowest speed reached',
    );
    expect(app.settings.voiceSpeed, 0.75);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('voice-faster')));
      await tester.pumpAndSettle();
    }
    expect(speed(), '1.25×');
    expect(app.player.speeds.last, 1.25);
  });

  testWidgets('auto-advance moves on after the voice finishes', (tester) async {
    final app = TestApp();
    await app.settings.setVoiceEnabled(true);
    await app.settings.setPauseSeconds(1);
    await pumpApp(tester, app);
    await startRosary(tester);
    await tester.tap(find.byKey(const Key('auto-advance')));
    await tester.pumpAndSettle();
    expect(app.settings.autoAdvance, isTrue);
    // The guide was created before the chip was pressed; it follows the chip.
    app.player.finish();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), "Apostles' Creed");
  });

  testWidgets('auto-advance waits on the mystery announcement and says so', (tester) async {
    final app = TestApp();
    await app.settings.setVoiceEnabled(true);
    await app.settings.setAutoAdvance(true);
    await app.settings.setPauseSeconds(1);
    await pumpApp(tester, app);
    await startRosary(tester);
    while (find.byKey(const Key('read-passage')).evaluate().isEmpty) {
      expect(find.byKey(const Key('auto-advance-waits')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    final announcement = stepTitle(tester);
    expect(find.byKey(const Key('auto-advance-waits')), findsOneWidget);
    app.player.finish();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), announcement);
  });

  group('auto-scroll', () {
    const creed = 'assets/audio/en/prayer_apostles_creed.mp3';
    ScrollPosition panel(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.ancestor(of: find.byKey(const Key('step-title')), matching: find.byType(Scrollable)),
        )
        .position;

    Future<TestApp> atTheCreed(WidgetTester tester, {bool autoScroll = true}) async {
      final app = TestApp();
      await app.settings.setVoiceEnabled(true);
      await app.settings.setAutoScroll(autoScroll);
      await pumpApp(tester, app, size: const Size(400, 600));
      await startRosary(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(panel(tester).maxScrollExtent, greaterThan(0), reason: 'the Creed overflows');
      return app;
    }

    testWidgets('a long prayer scrolls along with the voice', (tester) async {
      final app = await atTheCreed(tester);
      app.player.start('assets/audio/en/guide_creed.mp3', const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(panel(tester).pixels, 0, reason: 'not during the instruction');

      app.player.start(creed, const Duration(seconds: 40));
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      final max = panel(tester).maxScrollExtent;
      expect(panel(tester).pixels, closeTo(max / 2, max * 0.05));
      await tester.pump(const Duration(seconds: 20));
      expect(panel(tester).pixels, max);
    });

    testWidgets('touching the text hands control back to the person', (tester) async {
      final app = await atTheCreed(tester);
      await tester.drag(find.byKey(const Key('step-title')), const Offset(0, -50));
      await tester.pumpAndSettle();
      final where = panel(tester).pixels;
      app.player.start(creed, const Duration(seconds: 40));
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      expect(panel(tester).pixels, where);
    });

    testWidgets('stopping the voice stops the scroll', (tester) async {
      final app = await atTheCreed(tester);
      app.player.start(creed, const Duration(seconds: 40));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.byKey(const Key('voice-toggle')));
      await tester.pump();
      final where = panel(tester).pixels;
      expect(where, greaterThan(0));
      await tester.pump(const Duration(seconds: 20));
      expect(panel(tester).pixels, where);
    });

    testWidgets('can be turned off in settings', (tester) async {
      final app = await atTheCreed(tester, autoScroll: false);
      app.player.start(creed, const Duration(seconds: 40));
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      expect(panel(tester).pixels, 0);
    });
  });

  testWidgets('the remote play/pause key toggles the voice', (tester) async {
    final app = TestApp(isTelevision: true);
    await pumpApp(tester, app, size: const Size(960, 540));
    await startRosary(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.pumpAndSettle();
    expect(app.settings.voiceEnabled, isTrue);
    expect(app.player.played, hasLength(1));
  });

  testWidgets('a language without recordings offers no voice', (tester) async {
    final app = TestApp(audio: const AudioCatalog.empty());
    await pumpApp(tester, app);
    await startRosary(tester);
    expect(find.byKey(const Key('voice-toggle')), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('No voice is available in this language yet'), 200);
    expect(find.text('No voice is available in this language yet'), findsOneWidget);
  });

  testWidgets('voice settings are saved', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app, size: const Size(400, 1500));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read aloud'));
    await tester.tap(find.text('Read the guidance aloud'));
    await tester.tap(find.text('Auto-advance'));
    await tester.tap(find.byKey(const Key('auto-scroll')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('pause-slider')), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(app.settings.voiceEnabled, isTrue);
    expect(app.settings.readGuidanceAloud, isFalse);
    expect(app.settings.autoAdvance, isTrue);
    expect(app.settings.pauseSeconds, SettingsController.maxPause);
    expect(await app.store.getBool(SettingsController.autoAdvanceKey), isTrue);
    expect(await app.store.getString(SettingsController.pauseKey), '5');
    expect(app.settings.autoScroll, isFalse);
    expect(await app.store.getBool(SettingsController.autoScrollKey), isFalse);
  });

  testWidgets('the credits page lists the voice licences', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app, size: const Size(400, 1200));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('About and credits'), 200);
    await tester.tap(find.text('About and credits'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
