@Tags(['golden'])
library;

import 'package:crc/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../ui/app_flow_test.dart' show pumpApp, startRosary;

/// Regenerate after an intentional UI change with:
///   flutter test --update-goldens test/goldens
void main() {
  const formFactors = {
    'phone': (Size(400, 800), false),
    'tablet': (Size(1024, 768), false),
    'tv': (Size(960, 540), true),
  };

  for (final theme in AppThemeMode.values) {
    for (final MapEntry(key: name, value: (size, tv)) in formFactors.entries) {
      testWidgets('home · ${theme.name} · $name', (tester) async {
        final app = TestApp(isTelevision: tv);
        await app.themeManager.setMode(theme);
        await pumpApp(tester, app, size: size);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_${theme.name}_$name.png'),
        );
      });

      testWidgets('rosary · ${theme.name} · $name', (tester) async {
        final app = TestApp(isTelevision: tv);
        await app.themeManager.setMode(theme);
        await pumpApp(tester, app, size: size);
        await startRosary(tester);
        // Fourth Hail Mary of the first decade.
        for (var i = 0; i < 12; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        }
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/rosary_${theme.name}_$name.png'),
        );
      });
    }
  }
}
