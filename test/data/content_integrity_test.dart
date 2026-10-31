import 'dart:convert';
import 'dart:io';

import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/models/learn_page.dart';
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

      test('every prayer has its background, with Scripture where English has it', () {
        for (final prayer in content.prayers) {
          final note = content.note(prayer.id);
          expect(note, isNotNull, reason: 'no note for ${prayer.id}');
          expect(note!.origin.hasLanguage(lang), isTrue, reason: '${prayer.id} origin [$lang]');
          expect(note.use.hasLanguage(lang), isTrue, reason: '${prayer.id} use [$lang]');
          if (note.scripture case final refs?) {
            expect(refs.hasLanguage(lang), isTrue, reason: '${prayer.id} scripture [$lang]');
          }
        }
      });

      test('every Learn topic has its page, with as many sections as English', () {
        for (final topic in LearnTopic.values) {
          final page = content.learnPage(topic);
          expect(page, isNotNull, reason: 'no page for $topic');
          expect(page!.title.hasLanguage(lang), isTrue, reason: '$topic title [$lang]');
          expect(page.summary.hasLanguage(lang), isTrue, reason: '$topic summary [$lang]');
          expect(page.sections, isNotEmpty);
          for (final (i, section) in page.sections.indexed) {
            expect(section.heading.hasLanguage(lang), isTrue, reason: '$topic $i heading [$lang]');
            expect(section.text.hasLanguage(lang), isTrue, reason: '$topic $i text [$lang]');
          }
          final sections =
              (((jsonDecode(File(ContentRepository.learnPath(lang)).readAsStringSync())
                              as Map<String, dynamic>)['topics']
                          as Map<String, dynamic>)[topic.name]
                      as Map<String, dynamic>)['sections']
                  as List;
          expect(sections, hasLength(page.sections.length), reason: '$topic sections [$lang]');
        }
      });

      test('Learn pages are about known topics', () {
        final topics =
            (jsonDecode(File(ContentRepository.learnPath(lang)).readAsStringSync())
                    as Map<String, dynamic>)['topics']
                as Map<String, dynamic>;
        expect(topics.keys.toSet(), LearnTopic.values.map((t) => t.name).toSet());
      });

      test('notes are about prayers that exist', () {
        final notes =
            (jsonDecode(File(ContentRepository.notesPath(lang)).readAsStringSync())
                    as Map<String, dynamic>)['notes']
                as Map<String, dynamic>;
        expect(notes.keys.toSet(), content.prayers.map((p) => p.id).toSet());
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
