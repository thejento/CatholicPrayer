import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> pumpHome(WidgetTester tester, TestApp app, {Size size = const Size(400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
}

/// The page's list; items below the fold are not built until scrolled to.
final list = find.byType(Scrollable).last;

String text(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('the day opens an explanation of the season, colour and mysteries', (tester) async {
    await pumpHome(
      tester,
      TestApp(now: DateTime(2026, 12, 6)),
      size: const Size(400, 3000),
    ); // whole page
    await tester.tap(find.byKey(const Key('liturgical-day')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'About today'), findsOneWidget);
    expect(text(tester, 'about-day-name'), 'Second Sunday of Advent');
    expect(text(tester, 'about-season'), startsWith('Advent opens the Church year'));
    expect(text(tester, 'about-color'), startsWith('Violet'));
    expect(text(tester, 'about-today-set'), 'Today: the Joyful Mysteries.');
    expect(find.textContaining('Sundays of Advent, the Joyful'), findsOneWidget);
    expect(find.text('• Monday · Saturday: Joyful Mysteries'), findsOneWidget);
    expect(find.text('• Wednesday · Sunday: Glorious Mysteries'), findsOneWidget);
    expect(find.text('• Thursday: Luminous Mysteries'), findsOneWidget);
    expect(find.textContaining('Saint John Paul II in 2002'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('5. The Coronation of Mary'), 300, scrollable: list);
  });

  testWidgets('the suggestion opens the same explanation, in the app language', (tester) async {
    await pumpHome(tester, TestApp(now: DateTime(2026, 3, 15), locale: const Locale('es')));
    await tester.tap(find.byKey(const Key('suggested-today')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sobre el día de hoy'), findsOneWidget);
    expect(text(tester, 'about-day-name'), 'IV Domingo de Cuaresma');
    expect(text(tester, 'about-color'), startsWith('Rosa'));
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('• Martes · Viernes: Misterios Dolorosos'), findsOneWidget);
  });

  testWidgets('the saint opens a card with the rank explained and a Vatican News link', (
    tester,
  ) async {
    final app = TestApp(now: DateTime(2026, 10, 7));
    await pumpHome(tester, app);
    await tester.tap(find.byKey(const Key('saint-of-the-day')));
    await tester.pumpAndSettle();

    expect(find.text('Saint of the day'), findsOneWidget);
    expect(find.textContaining('Memorial: A saint the whole Church remembers'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saint-link')));
    await tester.pumpAndSettle();
    expect(app.openedLinks, [Uri.parse('https://www.vaticannews.va/en/saints/10/07.html')]);
  });

  testWidgets('optional memorials are all explained; a failed link says so', (tester) async {
    final app = TestApp(now: DateTime(2026, 2, 3), locale: const Locale('fr'))..linksOpen = false;
    await pumpHome(tester, app);
    await tester.tap(find.byKey(const Key('saint-of-the-day')));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Saint Blaise, évêque et martyr')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Saint Anschaire, évêque')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('saint-link')));
    await tester.pumpAndSettle();
    expect(app.openedLinks.single.toString(), endsWith('/fr/saint-du-jour/02/03.html'));
    expect(find.text("Impossible d'ouvrir la page."), findsOneWidget);
  });

  testWidgets('on TV the address is shown instead of a browser link', (tester) async {
    final app = TestApp(now: DateTime(2026, 10, 7), isTelevision: true);
    await pumpHome(tester, app, size: const Size(960, 540));
    await tester.ensureVisible(find.byKey(const Key('saint-of-the-day')));
    await tester.tap(find.byKey(const Key('saint-of-the-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saint-link')), findsNothing);
    expect(find.text('https://www.vaticannews.va/en/saints/10/07.html'), findsOneWidget);
  });

  testWidgets('the saint card and About today are accessible', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, TestApp(now: DateTime(2026, 2, 3)));
    await tester.tap(find.byKey(const Key('saint-of-the-day')));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
