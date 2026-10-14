import 'dart:convert';
import 'dart:io';

import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// These tests fail CI when a translation is missing (ADR-005).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final content = loadRealContent();
  final requiredPrayerIds = buildRosarySequence().map((s) => s.prayerId).nonNulls.toSet();

  for (final lang in contentLanguages) {
    group('content [$lang]', () {
      test('has every prayer the Rosary needs, with title and text', () {
        for (final id in requiredPrayerIds) {
          final prayer = content.prayer(id);
          expect(prayer, isNotNull, reason: 'missing prayer $id');
          expect(prayer!.title.hasLanguage(lang), isTrue, reason: '$id title [$lang]');
          expect(prayer.text.hasLanguage(lang), isTrue, reason: '$id text [$lang]');
        }
      });

      test('has a title and five complete mysteries for every set', () {
        for (final set in MysterySet.values) {
          expect(content.mysterySetTitle(set).hasLanguage(lang), isTrue, reason: '$set [$lang]');
          final mysteries = content.mysteriesOf(set);
          expect(mysteries, hasLength(mysteriesPerSet));
          for (final m in mysteries) {
            expect(m.title.hasLanguage(lang), isTrue, reason: '$set ${m.number} title');
            expect(m.scripture.hasLanguage(lang), isTrue, reason: '$set ${m.number} scripture');
            expect(m.fruit.hasLanguage(lang), isTrue, reason: '$set ${m.number} fruit');
          }
        }
      });

      test('prayer file lists the same ids as English', () {
        List<String> ids(String l) => [
          for (final p
              in (jsonDecode(File('assets/data/prayers/$l.json').readAsStringSync())
                      as Map<String, dynamic>)['prayers']
                  as List)
            (p as Map<String, dynamic>)['id'] as String,
        ];
        expect(ids(lang), ids('en'));
      });
    });
  }

  test('the declared assets load through the asset bundle', () async {
    final loaded = await ContentRepository.load(rootBundle);
    expect(loaded.prayers.map((p) => p.id), containsAll(requiredPrayerIds));
  });

  group('ARB files', () {
    Map<String, dynamic> arb(String l) =>
        jsonDecode(File('lib/src/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
    Set<String> keys(String l) => arb(l).keys.where((k) => !k.startsWith('@')).toSet();

    for (final lang in contentLanguages.where((l) => l != 'en')) {
      test('[$lang] has exactly the same keys as English', () {
        expect(keys(lang), keys('en'));
      });

      test('[$lang] keeps every placeholder', () {
        final en = arb('en');
        final other = arb(lang);
        for (final key in keys('en')) {
          final placeholders = RegExp(r'\{(\w+)\}').allMatches(en[key] as String).map((m) => m[1]);
          for (final p in placeholders) {
            expect(other[key] as String, contains('{$p}'), reason: '$key [$lang]');
          }
        }
      });
    }
  });
}
