import 'package:crc/src/l10n/generated/app_localizations_en.dart';
import 'package:crc/src/ui/liturgy_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> pumpHome(WidgetTester tester, TestApp app) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
}

String dayLine(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(const Key('liturgical-day')), matching: find.byType(Text)),
    )
    .data!;

void main() {
  test('ordinals in each language', () {
    expect([1, 2, 7, 8, 11, 21, 22, 23, 34].map((n) => liturgicalOrdinal(n, 'en')), [
      'First',
      'Second',
      'Seventh',
      '8th',
      '11th',
      '21st',
      '22nd',
      '23rd',
      '34th',
    ]);
    expect([1, 4, 9, 14, 29, 34].map((n) => liturgicalOrdinal(n, 'es')), [
      'I',
      'IV',
      'IX',
      'XIV',
      'XXIX',
      'XXXIV',
    ]);
    expect([1, 2, 34].map((n) => liturgicalOrdinal(n, 'fr')), ['1er', '2e', '34e']);
  });

  test('every named day and season has a name', () {
    final l10n = AppLocalizationsEn();
    for (var date = DateTime(2026); date.year < 2027; date = date.add(const Duration(days: 1))) {
      expect(liturgicalDayNameFor(l10n, date), isNotEmpty);
    }
  });

  testWidgets('a weekday shows the season', (tester) async {
    await pumpHome(tester, TestApp()); // Monday 12 October 2026
    expect(dayLine(tester), 'Ordinary Time');
    expect(find.byKey(const Key('sunday-note')), findsNothing);
  });

  testWidgets('a Sunday of Advent suggests the Joyful mysteries and says why', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 12, 6)));
    expect(dayLine(tester), 'Second Sunday of Advent');
    expect(find.text('Joyful Mysteries'), findsOneWidget);
    expect(find.textContaining('Sundays of Advent'), findsOneWidget);
  });

  testWidgets('a Sunday of Lent suggests the Sorrowful mysteries', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 3, 15)));
    expect(dayLine(tester), 'Fourth Sunday of Lent');
    expect(find.text('Sorrowful Mysteries'), findsOneWidget);
  });

  testWidgets('names follow the language', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 10, 18), locale: const Locale('es')));
    expect(dayLine(tester), 'XXIX Domingo del Tiempo Ordinario');
    await pumpHome(tester, TestApp(now: DateTime(2026, 12, 6), locale: const Locale('fr')));
    expect(dayLine(tester), "2e dimanche de l'Avent");
    await pumpHome(tester, TestApp(now: DateTime(2026, 4, 3), locale: const Locale('fr')));
    expect(dayLine(tester), 'Vendredi saint');
  });

  testWidgets('the Sunday reminder names the season\'s mysteries', (tester) async {
    final app = TestApp(now: DateTime(2026, 11, 30), isAndroid: true); // Monday of Advent
    await pumpHome(tester, app);
    await app.reminder.setEnabled(true);
    final sunday = app.reminders.scheduled.firstWhere((r) => r.weekday == DateTime.sunday);
    expect(sunday.body, 'Today: the Joyful Mysteries.');
  });

  testWidgets('Home shows the saint of the day and its rank', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 10, 7)));
    expect(find.text('Our Lady of the Rosary'), findsOneWidget);
    expect(find.text('Memorial'), findsOneWidget);
  });

  testWidgets('optional memorials of the same day are offered together', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 2, 3)));
    expect(find.text('Saint Blaise, bishop and martyr'), findsOneWidget);
    expect(find.text('Optional memorial'), findsOneWidget);
    expect(find.text('or Saint Ansgar, bishop'), findsOneWidget);
  });

  testWidgets('saints follow the language', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 10, 15), locale: const Locale('fr')));
    expect(find.text("Sainte Thérèse de Jésus, vierge et docteur de l'Église"), findsOneWidget);
    expect(find.text('Mémoire'), findsOneWidget);
  });

  testWidgets('no saint row on Easter Sunday', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 4, 5)));
    expect(find.byKey(const Key('saint-of-the-day')), findsNothing);
    expect(dayLine(tester), 'Easter Sunday');
  });

  testWidgets('a busy Home (season, two saints, Sunday note) is accessible at 200 % text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, TestApp(now: DateTime(2026, 2, 3)));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(360, 640);
    await pumpHome(tester, TestApp(now: DateTime(2026, 12, 6))); // Sunday of Advent + note
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
