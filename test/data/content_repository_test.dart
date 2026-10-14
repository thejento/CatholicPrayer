import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/models/localized_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizedText', () {
    const text = LocalizedText({'en': 'Hello', 'fr': 'Bonjour'});

    test('returns the requested language', () => expect(text.of('fr'), 'Bonjour'));
    test('falls back to English', () => expect(text.of('es'), 'Hello'));
    test('falls back to any language without English', () {
      expect(const LocalizedText({'fr': 'Bonjour'}).of('es'), 'Bonjour');
    });
    test('is empty when there is no value', () => expect(const LocalizedText({}).of('en'), ''));
    test('hasLanguage ignores blank values', () {
      expect(const LocalizedText({'en': '  '}).hasLanguage('en'), isFalse);
      expect(text.hasLanguage('fr'), isTrue);
    });
  });

  group('ContentRepository.fromJson', () {
    Map<String, dynamic> prayers(String lang, List<(String, String)> items) => {
      'prayers': [
        for (final (id, title) in items) {'id': id, 'title': title, 'text': '$title text'},
      ],
    };
    Map<String, dynamic> mysteries(String title) => {
      'sets': {
        'joyful': {
          'title': title,
          'mysteries': [
            for (var i = 1; i <= 5; i++) {'title': 'M$i', 'scripture': 'S$i', 'fruit': 'F$i'},
          ],
        },
      },
    };

    final repo = ContentRepository.fromJson(
      prayers: {
        'fr': prayers('fr', [('b', 'B-fr'), ('a', 'A-fr')]),
        'en': prayers('en', [('a', 'A'), ('b', 'B')]),
      },
      mysteries: {'en': mysteries('Joyful'), 'fr': mysteries('Joyeux')},
    );

    test('merges languages and keeps the English order', () {
      expect(repo.prayers.map((p) => p.id), ['a', 'b']);
      expect(repo.prayer('a')!.titleFor('fr'), 'A-fr');
      expect(repo.prayer('b')!.textFor('en'), 'B text');
    });

    test('returns null for unknown prayers', () => expect(repo.prayer('zzz'), isNull));

    test('exposes mystery sets by decade', () {
      expect(repo.mysterySetTitle(MysterySet.joyful).of('fr'), 'Joyeux');
      expect(repo.mystery(MysterySet.joyful, 3).title.of('en'), 'M3');
      expect(repo.mystery(MysterySet.joyful, 5).number, 5);
    });

    test('tolerates a set missing from the files', () {
      expect(repo.mysterySetTitle(MysterySet.glorious).of('en'), '');
    });
  });
}
