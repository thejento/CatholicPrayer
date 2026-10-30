import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> openLibrary(WidgetTester tester, TestApp app) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.menu_book_outlined)); // Prayer Library
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the library lists the Rosary prayers, then other prayers', (tester) async {
    await openLibrary(tester, TestApp());
    final rosary = tester.getTopLeft(find.text('Prayers of the Rosary')).dy;
    final other = tester.getTopLeft(find.text('Other prayers')).dy;
    expect(tester.getTopLeft(find.text('Hail Mary')).dy, inExclusiveRange(rosary, other));
    for (final title in [
      'Memorare',
      'Prayer to Saint Michael the Archangel',
      'Come, Holy Spirit',
      'Prayer to the Guardian Angel',
      'Act of Contrition',
      'The Angelus',
      'Regina Caeli (Easter Time)',
      'For the Intentions of the Holy Father',
    ]) {
      expect(tester.getTopLeft(find.text(title)).dy, greaterThan(other), reason: title);
    }
  });

  testWidgets('a new prayer opens in the app language', (tester) async {
    await openLibrary(tester, TestApp(locale: const Locale('fr')));
    expect(find.text('Autres prières'), findsOneWidget);
    await tester.tap(find.text('Souvenez-vous'));
    await tester.pumpAndSettle();
    expect(find.textContaining('très miséricordieuse Vierge Marie'), findsOneWidget);
  });

  testWidgets('Spanish has the same prayers', (tester) async {
    await openLibrary(tester, TestApp(locale: const Locale('es')));
    expect(find.text('Otras oraciones'), findsOneWidget);
    expect(find.text('Acordaos'), findsOneWidget);
    expect(find.text('El Ángelus'), findsOneWidget);
  });
}
