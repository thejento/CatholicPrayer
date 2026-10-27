import 'package:crc/src/domain/liturgical_calendar.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  test('Easter dates', () {
    const known = {
      2008: (3, 23),
      2019: (4, 21),
      2024: (3, 31),
      2025: (4, 20),
      2026: (4, 5),
      2027: (3, 28),
      2038: (4, 25),
      2285: (3, 22),
    };
    known.forEach((year, md) => expect(easterSunday(year), DateTime.utc(year, md.$1, md.$2)));
  });

  test('Advent, Baptism and Holy Family dates', () {
    expect(firstSundayOfAdvent(2024), DateTime.utc(2024, 12, 1));
    expect(firstSundayOfAdvent(2025), DateTime.utc(2025, 11, 30));
    expect(firstSundayOfAdvent(2026), DateTime.utc(2026, 11, 29));
    expect(firstSundayOfAdvent(2022), DateTime.utc(2022, 11, 27)); // Christmas on a Sunday
    expect(baptismOfTheLord(2026), DateTime.utc(2026, 1, 11));
    expect(baptismOfTheLord(2019), DateTime.utc(2019, 1, 13)); // 6 January was a Sunday
    expect(holyFamily(2026), DateTime.utc(2026, 12, 27));
    expect(holyFamily(2022), DateTime.utc(2022, 12, 30)); // no Sunday after Christmas
  });

  // One check per kind of day, mostly in 2026 (Easter 5 April).
  final expected = {
    d(2026, 1, 1): const LiturgicalDay(
      season: Season.christmas,
      color: LiturgicalColor.white,
      special: SpecialDay.maryMotherOfGod,
    ),
    d(2026, 1, 4): const LiturgicalDay(season: Season.christmas, color: LiturgicalColor.white),
    d(2026, 1, 6): const LiturgicalDay(
      season: Season.christmas,
      color: LiturgicalColor.white,
      special: SpecialDay.epiphany,
    ),
    d(2026, 1, 11): const LiturgicalDay(
      season: Season.christmas,
      color: LiturgicalColor.white,
      special: SpecialDay.baptismOfTheLord,
    ),
    d(2026, 1, 12): const LiturgicalDay(season: Season.ordinary, color: LiturgicalColor.green),
    d(2026, 2, 15): const LiturgicalDay(
      season: Season.ordinary,
      color: LiturgicalColor.green,
      sundayNumber: 6,
    ),
    d(2026, 2, 18): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.violet,
      special: SpecialDay.ashWednesday,
    ),
    d(2026, 2, 19): const LiturgicalDay(season: Season.lent, color: LiturgicalColor.violet),
    d(2026, 2, 22): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.violet,
      sundayNumber: 1,
    ),
    d(2026, 3, 15): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.rose,
      sundayNumber: 4,
    ),
    d(2026, 3, 29): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.red,
      special: SpecialDay.palmSunday,
    ),
    d(2026, 4, 2): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.white,
      special: SpecialDay.holyThursday,
    ),
    d(2026, 4, 3): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.red,
      special: SpecialDay.goodFriday,
    ),
    d(2026, 4, 4): const LiturgicalDay(
      season: Season.lent,
      color: LiturgicalColor.violet,
      special: SpecialDay.holySaturday,
    ),
    d(2026, 4, 5): const LiturgicalDay(
      season: Season.easter,
      color: LiturgicalColor.white,
      special: SpecialDay.easterSunday,
    ),
    d(2026, 4, 12): const LiturgicalDay(
      season: Season.easter,
      color: LiturgicalColor.white,
      sundayNumber: 2,
    ),
    d(2026, 5, 14): const LiturgicalDay(
      season: Season.easter,
      color: LiturgicalColor.white,
      special: SpecialDay.ascension,
    ),
    d(2026, 5, 24): const LiturgicalDay(
      season: Season.easter,
      color: LiturgicalColor.red,
      special: SpecialDay.pentecost,
    ),
    d(2026, 5, 25): const LiturgicalDay(season: Season.ordinary, color: LiturgicalColor.green),
    d(2026, 5, 31): const LiturgicalDay(
      season: Season.ordinary,
      color: LiturgicalColor.white,
      special: SpecialDay.trinitySunday,
    ),
    d(2026, 6, 7): const LiturgicalDay(
      season: Season.ordinary,
      color: LiturgicalColor.green,
      sundayNumber: 10,
    ),
    d(2026, 10, 18): const LiturgicalDay(
      season: Season.ordinary,
      color: LiturgicalColor.green,
      sundayNumber: 29,
    ),
    d(2026, 11, 22): const LiturgicalDay(
      season: Season.ordinary,
      color: LiturgicalColor.white,
      special: SpecialDay.christTheKing,
    ),
    d(2026, 11, 29): const LiturgicalDay(
      season: Season.advent,
      color: LiturgicalColor.violet,
      sundayNumber: 1,
    ),
    d(2026, 12, 13): const LiturgicalDay(
      season: Season.advent,
      color: LiturgicalColor.rose,
      sundayNumber: 3,
    ),
    d(2026, 12, 24): const LiturgicalDay(season: Season.advent, color: LiturgicalColor.violet),
    d(2026, 12, 25): const LiturgicalDay(
      season: Season.christmas,
      color: LiturgicalColor.white,
      special: SpecialDay.christmas,
    ),
    d(2026, 12, 27): const LiturgicalDay(
      season: Season.christmas,
      color: LiturgicalColor.white,
      special: SpecialDay.holyFamily,
    ),
    d(2026, 12, 31): const LiturgicalDay(season: Season.christmas, color: LiturgicalColor.white),
  };
  expected.forEach((date, day) {
    test(
      '${date.toIso8601String().substring(0, 10)} is $day',
      () => expect(liturgicalDay(date), day),
    );
  });

  test('every day of a century has a season, and Sundays are numbered sensibly', () {
    for (
      var date = DateTime.utc(2000);
      date.year < 2100;
      date = date.add(const Duration(days: 1))
    ) {
      final day = liturgicalDay(date);
      if (day.sundayNumber case final n?) {
        expect(date.weekday, DateTime.sunday);
        final max = switch (day.season) {
          Season.advent => 4,
          Season.lent => 5,
          Season.easter => 7,
          Season.ordinary => 34,
          Season.christmas => 0,
        };
        expect(n, inInclusiveRange(1, max), reason: '$date $day');
      }
      expect(day.toString(), contains(day.season.name));
    }
  });

  group('Sunday mysteries follow the season', () {
    test('Advent and Christmas Time: Joyful', () {
      expect(suggestedMysterySet(d(2026, 12, 6)), MysterySet.joyful);
      expect(suggestedMysterySet(d(2027, 1, 3)), MysterySet.joyful);
    });
    test('Lent: Sorrowful', () {
      expect(suggestedMysterySet(d(2026, 3, 1)), MysterySet.sorrowful);
      expect(suggestedMysterySet(d(2026, 3, 29)), MysterySet.sorrowful); // Palm Sunday
    });
    test('otherwise Glorious', () {
      expect(suggestedMysterySet(d(2026, 4, 5)), MysterySet.glorious); // Easter
      expect(suggestedMysterySet(d(2026, 10, 18)), MysterySet.glorious);
    });
    test('weekdays keep their mysteries', () {
      expect(suggestedMysterySet(d(2026, 12, 7)), MysterySet.joyful); // Monday of Advent
      expect(suggestedMysterySet(d(2026, 3, 3)), MysterySet.sorrowful); // Tuesday of Lent
      expect(suggestedMysterySet(d(2026, 3, 5)), MysterySet.luminous); // Thursday of Lent
    });
  });

  group('Sunday transfers (Canada, United States)', () {
    const canada = CalendarRegion.canada, usa = CalendarRegion.unitedStates;

    test('the Epiphany is the Sunday between 2 and 8 January', () {
      expect(epiphanyOf(2026), DateTime.utc(2026, 1, 6));
      expect(epiphanyOf(2026, canada), DateTime.utc(2026, 1, 4));
      expect(liturgicalDay(d(2026, 1, 4), canada).special, SpecialDay.epiphany);
      expect(liturgicalDay(d(2026, 1, 6), canada).special, isNull);
      expect(liturgicalDay(d(2026, 1, 6), canada).season, Season.christmas);
      expect(liturgicalDay(d(2026, 1, 6)).special, SpecialDay.epiphany);
      expect(epiphanyOf(2028, usa), DateTime.utc(2028, 1, 2));
    });

    test('the Baptism moves to Monday after an Epiphany on 7 or 8 January', () {
      expect(epiphanyOf(2029, canada), DateTime.utc(2029, 1, 7));
      expect(baptismOfTheLord(2029, canada), DateTime.utc(2029, 1, 8));
      expect(liturgicalDay(d(2029, 1, 8), canada).special, SpecialDay.baptismOfTheLord);
      expect(liturgicalDay(d(2029, 1, 9), canada).season, Season.ordinary);
      expect(liturgicalDay(d(2029, 1, 14), canada).sundayNumber, 2);
      expect(liturgicalDay(d(2029, 1, 14)).sundayNumber, 2);
      expect(baptismOfTheLord(2026, canada), DateTime.utc(2026, 1, 11));
      expect(liturgicalDay(d(2026, 1, 18), canada).sundayNumber, 2);
    });

    test('the Ascension is the Sunday after the 40th day', () {
      expect(liturgicalDay(d(2026, 5, 14)).special, SpecialDay.ascension);
      expect(liturgicalDay(d(2026, 5, 14), usa).special, isNull);
      expect(liturgicalDay(d(2026, 5, 17), usa).special, SpecialDay.ascension);
      expect(liturgicalDay(d(2026, 5, 17)).sundayNumber, 7);
      expect(ascensionOf(2026, canada), DateTime.utc(2026, 5, 17));
    });

    test('the rest of the year is unchanged', () {
      for (var day = d(2026, 1, 15); day.year == 2026; day = day.add(const Duration(days: 1))) {
        if (day.month == 5 && (day.day == 14 || day.day == 17)) continue;
        expect(liturgicalDay(day, canada), liturgicalDay(day), reason: '$day');
      }
    });
  });
}
