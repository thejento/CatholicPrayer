import 'package:crc/src/data/saint_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vatican News page of the day in each language', () {
    final day = DateTime(2026, 10, 7);
    expect(
      saintOfTheDayUrl(day, 'en').toString(),
      'https://www.vaticannews.va/en/saints/10/07.html',
    );
    expect(
      saintOfTheDayUrl(day, 'es').toString(),
      'https://www.vaticannews.va/es/santos/10/07.html',
    );
    expect(
      saintOfTheDayUrl(day, 'fr').toString(),
      'https://www.vaticannews.va/fr/saint-du-jour/10/07.html',
    );
  });

  test('dates without a page link to the saints index', () {
    expect(
      saintOfTheDayUrl(DateTime(2026, 11, 1), 'en').toString(),
      'https://www.vaticannews.va/en/saints.html',
    );
    expect(
      saintOfTheDayUrl(DateTime(2028, 2, 29), 'en').toString(),
      'https://www.vaticannews.va/en/saints.html',
    );
    expect(
      saintOfTheDayUrl(DateTime(2026, 11, 1), 'fr').toString(),
      endsWith('/fr/saint-du-jour/11/01.html'),
    );
  });

  test('other languages fall back to English', () {
    expect(
      saintOfTheDayUrl(DateTime(2026, 1, 2), 'pt').toString(),
      endsWith('/en/saints/01/02.html'),
    );
  });
}
