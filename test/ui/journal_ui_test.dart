import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/providers/journal_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, startRosary;

Future<void> finishRosary(WidgetTester tester) async {
  await startRosary(tester);
  for (var i = 0; i < 80; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  }
  await tester.pumpAndSettle();
}

Future<void> writeIntention(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('intention-field')), text);
  await tester.tap(find.byKey(const Key('intention-save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a finished Rosary goes into the journal, with an intention', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app, size: const Size(400, 1000));
    await finishRosary(tester);

    expect(find.byKey(const Key('journal-saved')), findsOneWidget);
    expect(app.journal.entries.single.mysterySet, MysterySet.joyful);
    expect(app.journal.entries.single.prayedAt, aMonday);

    await tester.tap(find.byKey(const Key('add-intention')));
    await tester.pumpAndSettle();
    await writeIntention(tester, 'For peace');
    expect(find.text('For peace'), findsOneWidget);
    expect(app.journal.entries.single.intention, 'For peace');

    // Going back and finishing again does not count it twice.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(app.journal.entries, hasLength(1));

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-journal')));
    await tester.pumpAndSettle();
    expect(find.text('1 Rosary this month'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Joyful Mysteries'), findsOneWidget);
    expect(find.text('For peace'), findsOneWidget);
  });

  testWidgets('cancelling the intention keeps the entry as it was', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app, size: const Size(400, 1000));
    await finishRosary(tester);
    await tester.tap(find.byKey(const Key('add-intention')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.journal.entries.single.intention, isEmpty);

    // Praying again adds a second entry.
    await tester.tap(find.text('Pray again'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 80; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pumpAndSettle();
    expect(app.journal.entries, hasLength(2));
  });

  testWidgets('entries can be edited, removed and cleared', (tester) async {
    final app = TestApp();
    await app.journal.record(
      JournalEntry(prayedAt: DateTime(2026, 9, 30, 21), mysterySet: MysterySet.glorious),
    );
    await app.journal.record(
      JournalEntry(prayedAt: DateTime(2026, 10, 3, 8), mysterySet: MysterySet.luminous),
    );
    await pumpApp(tester, app, size: const Size(400, 1000));
    await tester.tap(find.byKey(const Key('open-journal')));
    await tester.pumpAndSettle();

    expect(find.text('September 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('journal-menu-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add an intention'));
    await tester.pumpAndSettle();
    await writeIntention(tester, 'Thanksgiving');
    expect(app.journal.entries.first.intention, 'Thanksgiving');

    await tester.tap(find.byKey(const Key('journal-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from the journal'));
    await tester.pumpAndSettle();
    expect(app.journal.entries, hasLength(1));
    expect(find.text('September 2026'), findsNothing);

    await tester.tap(find.byKey(const Key('journal-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.journal.entries, hasLength(1));
    await tester.tap(find.byKey(const Key('journal-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal-clear-confirm')));
    await tester.pumpAndSettle();
    expect(app.journal.entries, isEmpty);
    expect(find.byKey(const Key('journal-empty')), findsOneWidget);
  });

  testWidgets('turned off in Settings: nothing is kept and Home hides it', (tester) async {
    final app = TestApp();
    await pumpApp(tester, app, size: const Size(400, 2400));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal-switch')));
    await tester.pumpAndSettle();
    expect(app.journal.enabled, isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-journal')), findsNothing);

    await finishRosary(tester);
    expect(find.byKey(const Key('journal-saved')), findsNothing);
    expect(app.journal.entries, isEmpty);
  });

  for (final (locale, count, month) in [
    (const Locale('es'), '1 Rosario este mes', 'octubre de 2026'),
    (const Locale('fr'), '1 Rosaire ce mois-ci', 'octobre 2026'),
  ]) {
    testWidgets('the journal speaks ${locale.languageCode}', (tester) async {
      final app = TestApp(locale: locale);
      await app.journal.record(JournalEntry(prayedAt: aMonday, mysterySet: MysterySet.joyful));
      await pumpApp(tester, app, size: const Size(400, 1000));
      await tester.tap(find.byKey(const Key('open-journal')));
      await tester.pumpAndSettle();
      expect(find.text(count), findsOneWidget);
      expect(find.textContaining(month), findsOneWidget);
    });
  }
}
