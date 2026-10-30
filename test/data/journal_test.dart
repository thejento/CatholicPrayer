import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/providers/journal_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monday = JournalEntry(
    prayedAt: DateTime(2026, 10, 12, 20, 15),
    mysterySet: MysterySet.joyful,
  );
  final friday = JournalEntry(
    prayedAt: DateTime(2026, 11, 6, 7),
    mysterySet: MysterySet.sorrowful,
    mode: RosaryMode.mysteriesOnly,
    intention: 'For my mother',
  );

  group('JournalEntry', () {
    test('round-trips through JSON', () {
      for (final e in [monday, friday]) {
        expect(JournalEntry.fromJson(e.toJson()), e);
      }
      expect(monday.toJson().keys, ['at', 'set'], reason: 'defaults are left out');
    });

    test('rejects anything unexpected', () {
      expect(JournalEntry.fromJson('x'), isNull);
      expect(JournalEntry.fromJson({'at': 'nope', 'set': 'joyful'}), isNull);
      expect(JournalEntry.fromJson({'at': '2026-10-12', 'set': 'cheerful'}), isNull);
      expect(JournalEntry.fromJson({'at': '2026-10-12', 'set': 'joyful', 'mode': 'x'}), isNull);
      expect(JournalEntry.fromJson({'at': '2026-10-12', 'set': 'joyful', 'intention': 3}), isNull);
    });

    test('compares by value', () {
      expect(monday.hashCode, monday.withIntention('').hashCode);
      expect(monday, isNot(monday.withIntention('Peace')));
    });
  });

  group('JournalController', () {
    test('is on by default, empty, and keeps entries newest first', () async {
      final store = InMemoryPreferencesStore();
      final journal = JournalController(store);
      await journal.load();
      expect(journal.enabled, isTrue);
      expect(journal.entries, isEmpty);

      await journal.record(monday);
      await journal.record(friday);
      final reloaded = JournalController(store);
      await reloaded.load();
      expect(reloaded.entries, [friday, monday]);
      expect(reloaded.countInMonth(DateTime(2026, 10, 30)), 1);
      expect(reloaded.countInMonth(DateTime(2025, 10, 30)), 0);
    });

    test('records nothing when turned off, and remembers that', () async {
      final store = InMemoryPreferencesStore();
      final journal = JournalController(store);
      await journal.setEnabled(false);
      expect(await journal.record(monday), isNull);
      expect(journal.entries, isEmpty);

      final reloaded = JournalController(store);
      await reloaded.load();
      expect(reloaded.enabled, isFalse);
    });

    test('edits the intention, trimmed and bounded', () async {
      final journal = JournalController(InMemoryPreferencesStore());
      await journal.record(monday);
      final updated = await journal.setIntention(monday, '  Peace  ');
      expect(updated.intention, 'Peace');
      expect(journal.entries.single, updated);

      final long = await journal.setIntention(updated, 'a' * 500);
      expect(long.intention, hasLength(JournalController.maxIntention));
      expect(await journal.setIntention(monday, 'gone'), monday, reason: 'unknown entry');
    });

    test('removes one entry or clears them all', () async {
      final store = InMemoryPreferencesStore();
      final journal = JournalController(store);
      await journal.record(monday);
      await journal.record(friday);
      await journal.remove(monday);
      expect(journal.entries, [friday]);
      await journal.clear();
      expect(journal.entries, isEmpty);
      expect(await store.getString(JournalController.entriesKey), isNull);
      await journal.clear();
    });

    test('a damaged journal loads as empty, skipping bad entries', () async {
      for (final (value, count) in [
        ('not json', 0),
        ('{"a":1}', 0),
        ('[{"set":"x"}, ${'{"at":"2026-10-12","set":"joyful"}'}]', 1),
      ]) {
        final journal = JournalController(
          InMemoryPreferencesStore({JournalController.entriesKey: value}),
        );
        await journal.load();
        expect(journal.entries, hasLength(count), reason: value);
      }
    });
  });
}
