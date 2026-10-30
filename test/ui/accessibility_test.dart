import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:crc/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Accessibility audit (F-10, F-11): every screen meets the Android tap-target,
/// labelled-control and text-contrast guidelines in both themes, and lays out
/// without overflow at 200 % text on a small phone.

typedef Visit = Future<void> Function(WidgetTester tester);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openRosary(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Pray the Rosary'));
  await tapAndSettle(tester, find.text('Start'));
}

Future<void> press(WidgetTester tester, LogicalKeyboardKey key, int times) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(key);
  }
  await tester.pumpAndSettle();
}

Future<void> openMysteriesOnly(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Pray the Rosary'));
  await tapAndSettle(tester, find.text('Mysteries only'));
  await tapAndSettle(tester, find.text('Start'));
}

/// Screens to audit, reached from Home the way a person would.
final Map<String, Visit> screens = {
  'home': (_) async {},
  'settings': (t) => tapAndSettle(t, find.byTooltip('Settings')),
  'prayer library': (t) => tapAndSettle(t, find.text('Prayer Library')),
  'about today': (t) => tapAndSettle(t, find.byKey(const Key('liturgical-day'))),
  'prayer detail': (t) async {
    await tapAndSettle(t, find.text('Prayer Library'));
    await tapAndSettle(t, find.text('Hail Mary'));
  },
  'about a prayer': (t) async {
    await tapAndSettle(t, find.text('Prayer Library'));
    await tapAndSettle(t, find.text('Hail Mary'));
    await tapAndSettle(t, find.byKey(const Key('about-prayer')));
  },
  'mystery picker': (t) => tapAndSettle(t, find.text('Pray the Rosary')),
  'rosary: prayer step': openRosary,
  'rosary: mystery announcement': (t) async {
    await openRosary(t);
    await press(t, LogicalKeyboardKey.arrowRight, 7);
  },
  'scripture passage': (t) async {
    await openRosary(t);
    await press(t, LogicalKeyboardKey.arrowRight, 7);
    await tapAndSettle(t, find.byKey(const Key('read-passage')));
  },
  'rosary: voice bar': (t) async {
    await openRosary(t);
    await tapAndSettle(t, find.byKey(const Key('voice-toggle')));
  },
  'mysteries only: opening prayers': openMysteriesOnly,
  'mysteries only: a mystery': (t) async {
    await openMysteriesOnly(t);
    await press(t, LogicalKeyboardKey.arrowRight, 2);
  },
  'rosary: completion': (t) async {
    await openRosary(t);
    await press(t, LogicalKeyboardKey.arrowRight, 80);
  },
  'divine mercy: a decade bead': (t) async {
    await tapAndSettle(t, find.byKey(const Key('divine-mercy')));
    await press(t, LogicalKeyboardKey.arrowRight, 5);
  },
  'divine mercy: completion': (t) async {
    await tapAndSettle(t, find.byKey(const Key('divine-mercy')));
    await press(t, LogicalKeyboardKey.arrowRight, 63);
  },
  'prayer journal': (t) async {
    await openRosary(t);
    await press(t, LogicalKeyboardKey.arrowRight, 80);
    await tapAndSettle(t, find.text('Back to home'));
    await tapAndSettle(t, find.byKey(const Key('open-journal')));
  },
};

TestApp appFor(AppThemeMode mode) {
  final app = TestApp();
  app.themeManager.setMode(mode);
  return app;
}

Future<void> pump(WidgetTester tester, TestApp app, Size size, {double textScale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in AppThemeMode.values) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} meets accessibility guidelines (${mode.name})', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, appFor(mode), const Size(400, 800));
        await entry.value(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  // The classic theme takes the colour of the day (§3.16): each one stays legible.
  final seasons = {
    'violet': DateTime(2026, 12, 1),
    'rose': DateTime(2026, 12, 13),
    'white': DateTime(2026, 12, 26),
    'red': DateTime(2026, 4, 3),
  };
  for (final MapEntry(key: colour, value: day) in seasons.entries) {
    for (final screen in ['home', 'settings', 'mystery picker', 'rosary: prayer step']) {
      testWidgets('$screen meets accessibility guidelines ($colour season)', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, TestApp(now: day), const Size(400, 800));
        await screens[screen]!(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  // A small phone held upright and sideways, and a TV (which adds its own 1.3× scale).
  const layouts = {
    'small phone': (Size(360, 640), false),
    'phone sideways': (Size(640, 360), false),
    'TV': (Size(960, 540), true),
  };
  for (final MapEntry(key: layout, value: (size, tv)) in layouts.entries) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} lays out at 200 % text ($layout)', (tester) async {
        await pump(tester, TestApp(isTelevision: tv), size, textScale: 2);
        await entry.value(tester);
        expect(tester.takeException(), isNull);
        final scaler = MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).last));
        expect(scaler.scale(10), greaterThanOrEqualTo(20), reason: '200 % text is applied');
      });
    }
  }

  testWidgets('continue card lays out at 200 % text', (tester) async {
    final app = TestApp();
    await app.savedSession.save(const SavedSession(mysterySet: MysterySet.sorrowful, index: 40));
    await pump(tester, app, const Size(360, 640), textScale: 2);
    expect(find.byKey(const Key('continue-rosary')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screen readers hear each step and can advance from the beads', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, TestApp(), const Size(400, 800));
    await openRosary(tester);

    expect(
      tester.getSemantics(find.byKey(const Key('step-title'))),
      isSemantics(label: 'Sign of the Cross', isHeader: true, isLiveRegion: true),
    );
    expect(
      tester.getSemantics(find.byType(LinearProgressIndicator)),
      isSemantics(label: 'Rosary progress'),
    );

    final beads = find.semantics.byLabel('Rosary, bead 1 of 61');
    expect(beads.evaluate().single, isSemantics(isButton: true, hasTapAction: true));
    tester.semantics.tap(beads);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const Key('step-title'))),
      isSemantics(label: "Apostles' Creed"),
    );
    handle.dispose();
  });
}
