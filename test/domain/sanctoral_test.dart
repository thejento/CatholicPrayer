import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/domain/sanctoral.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

List<String> ids(int y, int m, int d) =>
    celebrationsOn(DateTime(y, m, d)).map((c) => c.id).toList();

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
    final all = {...generalRomanCalendar.map((c) => c.id)};
    for (var date = DateTime(2026); date.year < 2030; date = date.add(const Duration(days: 1))) {
      all.addAll(celebrationsOn(date).map((c) => c.id));
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
