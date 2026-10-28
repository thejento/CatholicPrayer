import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  final scripture = loadRealScripture();
  final content = loadRealContent();

  test('every mystery has a passage in every language, with the same verses', () {
    for (final set in MysterySet.values) {
      for (var decade = 1; decade <= mysteriesPerSet; decade++) {
        final en = scripture.passage(set, decade, 'en')!;
        expect(en.verses, isNotEmpty, reason: '$set $decade');
        for (final lang in contentLanguages) {
          final p = scripture.passage(set, decade, lang)!;
          expect(p.chapter, en.chapter, reason: '$set $decade $lang');
          expect(p.verses.map((v) => v.number), en.verses.map((v) => v.number));
          expect(p.source, isNotEmpty);
          for (final v in p.verses) {
            expect(v.text.trim(), isNotEmpty, reason: '$set $decade $lang ${v.number}');
            // Brackets are kept: Crampon marks words added for sense that way.
            expect(v.text, isNot(matches(RegExp(r'[<>*\\]|\s{2}'))), reason: v.text);
          }
        }
      }
    }
  });

  test('no verse is cut short', () {
    // A verse ends a sentence or a clause. The francl file once stopped Luke 1:45 after
    // "Heureuse celle qui a cru" (completed in tool/scripture/build.py).
    // Torres Amat has no stop after Luke 2:8; the transcription is kept as published.
    const asPublished = {'es joyful 3 8'};
    for (final set in MysterySet.values) {
      for (var decade = 1; decade <= mysteriesPerSet; decade++) {
        for (final lang in contentLanguages) {
          for (final v in scripture.passage(set, decade, lang)!.verses) {
            final where = '$lang ${set.name} $decade ${v.number}';
            if (asPublished.contains(where)) continue;
            expect(v.text.trim(), matches(RegExp(r'[.,;:!?»”")\]—]$')), reason: where);
          }
        }
      }
    }
  });

  test('verses follow on without gaps', () {
    for (final set in MysterySet.values) {
      for (var decade = 1; decade <= mysteriesPerSet; decade++) {
        final numbers = scripture.passage(set, decade, 'en')!.verses.map((v) => v.number).toList();
        expect(numbers, List.generate(numbers.length, (i) => numbers.first + i));
      }
    }
  });

  test('the passage matches the reference shown on the mystery', () {
    for (final set in MysterySet.values) {
      for (var decade = 1; decade <= mysteriesPerSet; decade++) {
        for (final lang in contentLanguages) {
          final p = scripture.passage(set, decade, lang)!;
          final reference = content.mystery(set, decade).scripture.of(lang);
          final sep = lang == 'en' ? ':' : ',';
          expect(
            reference,
            contains('${p.chapter}$sep${p.verses.first.number}'),
            reason: reference,
          );
        }
      }
    }
  });

  test('the Annunciation says "full of grace", as the Hail Mary does', () {
    String verse28(String lang) => scripture
        .passage(MysterySet.joyful, 1, lang)!
        .verses
        .firstWhere((v) => v.number == 28)
        .text;
    expect(verse28('en'), contains('full of grace'));
    expect(verse28('es'), contains('llena de gracia'));
    expect(verse28('fr'), contains('pleine de grâce'));
  });

  test('falls back to English for a language without passages', () {
    expect(scripture.passage(MysterySet.joyful, 1, 'pt')!.verses.first.text, contains('Galilee'));
  });
}
