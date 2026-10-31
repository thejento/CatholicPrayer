import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/models/learn_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'app_flow_test.dart' show pumpApp, stepTitle;

/// "Learn about the Rosary" (F-33, DESIGN §3.23).
void main() {
  const size = Size(400, 3000);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    // Long pages build only what is on screen.
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 400, scrollable: find.byType(Scrollable).last);
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Home opens the topics, grouped, and a topic opens its page', (tester) async {
    await pumpApp(tester, TestApp(), size: size);
    await tap(tester, find.byKey(const Key('open-learn')));
    for (final topic in LearnTopic.values) {
      await tester.ensureVisible(find.byKey(Key('topic-${topic.slug}')));
    }
    expect(find.text('Other prayers on the beads'), findsOneWidget);

    await tap(tester, find.byKey(const Key('topic-rosary')));
    expect(find.text('What is the Rosary?'), findsOneWidget);
    expect(find.text('Where it comes from'), findsOneWidget);
    await tap(tester, find.byKey(const Key('learn-action')));
    expect(find.text('Choose the mysteries'), findsOneWidget);
  });

  testWidgets('each mystery card teaches its set and can start it', (tester) async {
    await pumpApp(tester, TestApp(), size: size);
    await tap(tester, find.text('Pray the Rosary'));
    expect(
      find.byKey(const Key('summary-sorrowful')),
      findsOneWidget,
      reason: 'the card shows the summary',
    );
    expect(
      tester.getSemantics(find.byKey(const Key('learn-sorrowful'))).label,
      contains('Sorrowful Mysteries'),
    );
    await tap(tester, find.byKey(const Key('learn-sorrowful')));
    expect(find.text('The Sorrowful Mysteries'), findsOneWidget);
    expect(find.text('The five mysteries'), findsOneWidget);
    expect(find.textContaining('The Agony in the Garden'), findsOneWidget);

    await tap(tester, find.text('Pray these mysteries'));
    expect(stepTitle(tester), 'Sign of the Cross');
    expect(find.widgetWithText(AppBar, 'Sorrowful Mysteries'), findsOneWidget);
  });

  testWidgets('the mode hint explains the ways to pray', (tester) async {
    await pumpApp(tester, TestApp(), size: size);
    await tap(tester, find.text('Pray the Rosary'));
    await tap(tester, find.byKey(const Key('learn-ways')));
    expect(find.text('Ways to pray'), findsOneWidget);
    expect(find.text('Privately or together'), findsOneWidget);
  });

  testWidgets('Settings explains the ending and leads back to it', (tester) async {
    await pumpApp(tester, TestApp(), size: size);
    await tap(tester, find.byTooltip('Settings'));
    await tap(tester, find.byKey(const Key('learn-ending')));
    expect(find.text('Ending the Rosary'), findsOneWidget);
    await tap(tester, find.byKey(const Key('learn-action')));
    expect(find.byKey(const Key('end-saint-michael')), findsOneWidget);
  });

  testWidgets('the chaplet page starts the chaplet', (tester) async {
    await pumpApp(tester, TestApp(), size: size);
    await tap(tester, find.byKey(const Key('open-learn')));
    await tap(tester, find.byKey(const Key('topic-divine-mercy')));
    expect(find.text('How it differs from the Rosary'), findsOneWidget);
    await tap(tester, find.text('Pray the chaplet'));
    expect(find.widgetWithText(AppBar, 'Divine Mercy Chaplet'), findsOneWidget);
  });

  testWidgets('pages follow the app language', (tester) async {
    await pumpApp(tester, TestApp(locale: const Locale('fr')), size: size);
    await tap(tester, find.byKey(const Key('open-learn')));
    expect(find.text('Découvrir le Rosaire'), findsWidgets);
    await tap(tester, find.byKey(const Key('topic-glorious')));
    expect(find.text('Les mystères glorieux'), findsOneWidget);
  });

  test('topics map to their sets and addresses', () {
    expect(LearnTopic.forSet(MysterySet.luminous), LearnTopic.luminous);
    expect(LearnTopic.luminous.mysterySet, MysterySet.luminous);
    expect(LearnTopic.ways.mysterySet, isNull);
    expect(LearnTopic.fromSlug('divine-mercy'), LearnTopic.divineMercy);
    expect(LearnTopic.fromSlug('x'), isNull);
  });
}
