import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/providers/theme_manager.dart';
import 'package:crc/src/theme/app_theme.dart';
import 'package:crc/src/ui/widgets/rosary_beads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> pumpApp(WidgetTester tester, TestApp app, {Size size = const Size(400, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
}

String stepTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('step-title'))).data!;

Future<void> startRosary(WidgetTester tester) async {
  await tester.tap(find.text('Pray the Rosary'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home suggests the mysteries of the day', (tester) async {
    await pumpApp(tester, TestApp()); // a Monday
    expect(find.text('Rosary Companion'), findsOneWidget);
    expect(find.text('Joyful Mysteries'), findsOneWidget);
  });

  testWidgets('home follows the injected clock', (tester) async {
    await pumpApp(tester, TestApp(now: DateTime(2026, 10, 15))); // Thursday
    expect(find.text('Luminous Mysteries'), findsOneWidget);
  });

  testWidgets('prayer library lists prayers and opens one', (tester) async {
    await pumpApp(tester, TestApp());
    await tester.tap(find.text('Prayer Library'));
    await tester.pumpAndSettle();
    expect(find.text('Hail Mary'), findsOneWidget);

    await tester.tap(find.text('Hail Mary'));
    await tester.pumpAndSettle();
    expect(find.textContaining('full of grace'), findsOneWidget);
  });

  testWidgets('mystery picker preselects today and allows another set', (tester) async {
    await pumpApp(tester, TestApp());
    await tester.tap(find.text('Pray the Rosary'));
    await tester.pumpAndSettle();
    expect(find.text('Suggested'), findsOneWidget);

    await tester.tap(find.text('Glorious Mysteries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Glorious Mysteries'), findsOneWidget);
  });

  testWidgets('guided Rosary shows guidance and advances with Next', (tester) async {
    await pumpApp(tester, TestApp());
    await startRosary(tester);

    expect(stepTitle(tester), 'Sign of the Cross');
    expect(find.text('Hold the crucifix and make the Sign of the Cross.'), findsOneWidget);
    expect(find.textContaining('Step 1 of 80'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), "Apostles' Creed");

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Sign of the Cross');
  });

  testWidgets('arrow keys (keyboard / TV D-pad) move through the steps', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(960, 540)); // Android TV
    await startRosary(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Our Father');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(stepTitle(tester), "Apostles' Creed");
  });

  testWidgets('Enter activates the focused Next button', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(960, 540));
    await startRosary(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(stepTitle(tester), "Apostles' Creed");
  });

  testWidgets('mystery announcement shows title, scripture and fruit', (tester) async {
    await pumpApp(tester, TestApp());
    await startRosary(tester);
    for (var i = 0; i < 7; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'The Annunciation');
    expect(find.text('Scripture: Luke 1:26-38'), findsOneWidget);
    expect(find.text('Fruit of the mystery: Humility'), findsOneWidget);
  });

  testWidgets('finishing all 80 steps shows the completion screen', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(1280, 800));
    await startRosary(tester);
    for (var i = 0; i < 80; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pumpAndSettle();
    expect(find.text('You prayed the Rosary!'), findsOneWidget);

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('Pray the Rosary'), findsOneWidget);
  });

  testWidgets('tapping the glowing bead advances', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(1000, 700));
    await startRosary(tester);
    // On the first step the crucifix (lowest point of the drawing) glows.
    final paint = find.byWidgetPredicate((w) => w is CustomPaint && w.painter != null).first;
    final box = tester.getRect(paint);
    await tester.tapAt(box.topLeft + beadPositions(box.size)[crucifixBead]);
    await tester.pumpAndSettle();
    expect(stepTitle(tester), "Apostles' Creed");
  });

  testWidgets('guidance can be turned off in settings', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show guidance'));
    await tester.pumpAndSettle();
    expect(app.settings.showGuidance, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await startRosary(tester);
    expect(find.byKey(const Key('step-guidance')), findsNothing);
  });

  testWidgets('switching theme in settings updates the app', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kid-friendly'));
    await tester.pumpAndSettle();
    expect(app.themeManager.mode, AppThemeMode.kidFriendly);
    expect(
      Theme.of(tester.element(find.text('Settings').first)).colorScheme.primary,
      AppTheme.themeFor(AppThemeMode.kidFriendly).colorScheme.primary,
    );
    expect(await app.store.getString(ThemeManager.prefsKey), 'kidFriendly');
  });

  testWidgets('changing language translates UI and prayers', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);

    // pageBack() looks for the English tooltip, so tap the button directly.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Misterios Gozosos'), findsOneWidget);
    await tester.tap(find.text('Rezar el Rosario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Señal de la Cruz');
  });

  for (final locale in const [Locale('fr'), Locale('es')]) {
    testWidgets('every step renders in ${locale.languageCode}', (tester) async {
      await pumpApp(tester, TestApp(locale: locale));
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      for (var i = 0; i < 80; i++) {
        expect(tester.takeException(), isNull);
        expect(stepTitle(tester), isNotEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
    });
  }

  testWidgets('each step opens scrolled to the top', (tester) async {
    await pumpApp(tester, TestApp(), size: const Size(400, 600));
    await startRosary(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // the Creed, a long text
    await tester.pumpAndSettle();
    ScrollPosition panel() => tester
        .state<ScrollableState>(
          find.ancestor(of: find.byKey(const Key('step-title')), matching: find.byType(Scrollable)),
        )
        .position;
    panel().jumpTo(panel().maxScrollExtent);
    await tester.pump();
    expect(panel().pixels, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(panel().pixels, 0);
  });
}
