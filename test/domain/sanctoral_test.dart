import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/domain/liturgical_calendar.dart';
import 'package:crc/src/domain/sanctoral.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

List<String> ids(int y, int m, int d, [CalendarRegion region = CalendarRegion.general]) =>
    celebrationsOn(DateTime(y, m, d), region).map((c) => c.id).toList();

const canada = CalendarRegion.canada, usa = CalendarRegion.unitedStates;

void main() {
  test('a weekday memorial', () {
    expect(ids(2026, 10, 7), ['our_lady_of_the_rosary']); // Wednesday
    expect(ids(2026, 8, 28), ['augustine']);
  });

  test('two optional memorials on one day', () {
    expect(ids(2026, 2, 3), ['blaise', 'ansgar']); // Tuesday
  });

  test('a higher rank comes first', () {
    // 2026-07-22 Wednesday: Mary Magdalene (feast).
    expect(celebrationsOn(DateTime(2026, 7, 22)).first.rank, Rank.feast);
  });

  test('Sundays: Ordinary Time yields to solemnities and feasts of the Lord only', () {
    expect(ids(2026, 10, 4), isEmpty); // Francis of Assisi on a Sunday
    expect(ids(2026, 11, 1), ['all_saints']); // Sunday
    expect(ids(2026, 8, 9), isEmpty); // Teresa Benedicta (optional) on a Sunday
    expect(ids(2020, 8, 16), isEmpty); // Stephen of Hungary on a Sunday
    expect(ids(2026, 8, 16), isEmpty); // Sunday
    expect(ids(2020, 9, 13), isEmpty); // John Chrysostom on a Sunday
    expect(ids(2020, 9, 14), ['exaltation_of_the_cross']); // Monday
    expect(ids(2025, 11, 9), ['dedication_of_the_lateran']); // Sunday, feast of the Lord
  });

  test('Sundays of Advent and Lent yield to nothing', () {
    expect(ids(2026, 12, 6), isEmpty); // Nicholas on the 2nd Sunday of Advent
    expect(ids(2026, 3, 8), isEmpty); // John of God on a Sunday of Lent
  });

  test('transferred solemnities', () {
    // 2024: 19 March is a Tuesday before Holy Week (24–30 March).
    expect(ids(2024, 3, 19), ['joseph']);
    // 2024: 25 March is Monday of Holy Week → Monday 8 April.
    expect(ids(2024, 3, 25), isEmpty);
    expect(ids(2024, 4, 8), ['annunciation']);
    // 2035: 19 March is in Holy Week (Easter 25 March) → Saturday 17 March,
    // which replaces Saint Patrick that year.
    expect(ids(2035, 3, 17), ['joseph']);
    // 2026: 8 December is a Tuesday; 2024: a Sunday of Advent → Monday 9.
    expect(ids(2024, 12, 8), isEmpty);
    expect(ids(2024, 12, 9).first, 'immaculate_conception');
    // 2022: the Sacred Heart fell on 24 June; John the Baptist moved to the 23rd.
    expect(ids(2022, 6, 24), ['sacred_heart']);
    expect(ids(2022, 6, 23), ['nativity_of_john_the_baptist']);
  });

  test('moveable celebrations after Pentecost (2026: Pentecost 24 May)', () {
    expect(ids(2026, 5, 25), ['mary_mother_of_the_church']);
    expect(ids(2026, 6, 4), ['corpus_christi']);
    expect(ids(2026, 6, 12), ['sacred_heart']);
    expect(ids(2026, 6, 13), ['immaculate_heart_of_mary']);
  });

  test('no saints on named days, in Holy Week or the Easter octave', () {
    expect(ids(2026, 12, 25), isEmpty);
    expect(ids(2026, 12, 27), isEmpty); // Holy Family replaces Saint John
    expect(ids(2026, 4, 1), isEmpty); // Wednesday of Holy Week
    expect(ids(2026, 4, 7), isEmpty); // Easter octave
    expect(ids(2026, 2, 18), isEmpty); // Ash Wednesday
  });

  test('every celebration has a name in every language', () {
    final saints = loadRealSaints();
    final all = {for (final r in CalendarRegion.values) ...calendarFor(r).map((c) => c.id)};
    for (var date = DateTime(2026); date.year < 2030; date = date.add(const Duration(days: 1))) {
      for (final r in CalendarRegion.values) {
        all.addAll(celebrationsOn(date, r).map((c) => c.id));
      }
    }
    for (final lang in contentLanguages) {
      expect(saints.ids(lang).toSet(), containsAll(all), reason: lang);
      for (final id in all) {
        expect(saints.name(id, lang), isNotEmpty);
      }
    }
    expect(saints.name('augustine', 'pt'), contains('Augustine'));
    expect(generalRomanCalendar.first.toString(), contains('basil_gregory'));
  });

  group('national calendars', () {
    test('Canada adds its saints and keeps the Canadian Martyrs as a feast', () {
      expect(ids(2026, 1, 7, canada), ['andre_bessette']); // Wednesday
      expect(ids(2026, 1, 8, canada), ['raymond_of_penyafort']); // moved from 7 January
      expect(ids(2026, 1, 7), ['raymond_of_penyafort']);
      expect(ids(2026, 9, 26, canada), ['north_american_martyrs']); // Saturday, a feast
      expect(ids(2026, 9, 25, canada), ['cosmas_damian']);
      expect(ids(2026, 10, 19, canada), ['paul_of_the_cross']);
      expect(ids(2026, 10, 19), ['north_american_martyrs', 'paul_of_the_cross']);
      expect(ids(2026, 10, 16, canada), ['marguerite_d_youville']);
      expect(ids(2026, 7, 27, canada), isEmpty);
      expect(ids(2027, 7, 26, canada), ['joachim_anne']); // Monday, a feast in Canada
      expect(calendarFor(canada).firstWhere((c) => c.id == 'joachim_anne').rank, Rank.feast);
    });

    test('the United States moves saints around its own days', () {
      expect(ids(2026, 1, 22, usa), ['day_of_prayer_for_the_unborn']); // Thursday
      expect(ids(2026, 1, 23, usa), ['vincent_deacon', 'marianne_cope']);
      // On a Sunday the day of prayer moves to Monday 23 January.
      expect(ids(2023, 1, 23, usa), [
        'day_of_prayer_for_the_unborn',
        'vincent_deacon',
        'marianne_cope',
      ]);
      expect(ids(2026, 7, 14, usa), ['kateri_tekakwitha']);
      expect(ids(2026, 7, 14), ['camillus_de_lellis']);
      expect(ids(2026, 11, 13, usa), ['frances_xavier_cabrini']);
    });

    test('Our Lady of Guadalupe is a feast in both, an optional memorial elsewhere', () {
      expect(celebrationsOn(DateTime(2026, 12, 12), canada).single.rank, Rank.feast);
      expect(celebrationsOn(DateTime(2026, 12, 12), usa).single.rank, Rank.feast);
      expect(celebrationsOn(DateTime(2026, 12, 12)).single.rank, Rank.optionalMemorial);
    });

    test('Corpus Christi moves to the Sunday', () {
      expect(ids(2026, 6, 4), ['corpus_christi']); // Thursday
      expect(ids(2026, 6, 4, canada), isEmpty);
      expect(ids(2026, 6, 7, canada), ['corpus_christi']);
      expect(ids(2026, 6, 7, usa), ['corpus_christi']);
    });

    test('each national calendar is in date order and names each day once', () {
      for (final national in [canadaCalendar, unitedStatesCalendar]) {
        var last = DateTime(2025, 12, 31);
        for (final c in national) {
          final date = DateTime(2026, c.month, c.day);
          expect(date.isBefore(last), isFalse, reason: c.id);
          last = date;
        }
        expect(national.map((c) => c.id).toSet(), hasLength(national.length));
      }
    });
  });

  test('the calendar is in date order with valid dates', () {
    var last = DateTime(2025, 12, 31);
    for (final c in generalRomanCalendar) {
      final date = DateTime(2026, c.month, c.day);
      expect(date.month, c.month, reason: c.id);
      expect(date.isBefore(last), isFalse, reason: c.id);
      last = date;
    }
  });
}
