import 'package:flutter/foundation.dart';

/// Seasons of the Church year (DESIGN §3.10).
enum Season { advent, christmas, lent, easter, ordinary }

enum LiturgicalColor { violet, rose, white, red, green }

/// Which calendar to follow: the General Roman Calendar, or a national one
/// on top of it (DESIGN §3.18). Canada and the United States keep Epiphany,
/// Ascension and Corpus Christi on a Sunday, and add their own saints.
enum CalendarRegion {
  general,
  canada,
  unitedStates;

  /// Whether Epiphany, Ascension and Corpus Christi move to a Sunday.
  bool get sundayTransfers => this != general;
}

/// Days with a name of their own in the General Roman Calendar.
enum SpecialDay {
  christmas,
  holyFamily,
  maryMotherOfGod,
  epiphany,
  baptismOfTheLord,
  ashWednesday,
  palmSunday,
  holyThursday,
  goodFriday,
  holySaturday,
  easterSunday,
  ascension,
  pentecost,
  trinitySunday,
  christTheKing,
}

/// Where a date falls in the Church year.
@immutable
class LiturgicalDay {
  const LiturgicalDay({required this.season, required this.color, this.special, this.sundayNumber});

  final Season season;
  final LiturgicalColor color;
  final SpecialDay? special;

  /// For an ordinary Sunday of its season: 1st, 2nd … Sunday of Advent, Lent,
  /// Easter or Ordinary Time. Null on weekdays and named days.
  final int? sundayNumber;

  @override
  bool operator ==(Object other) =>
      other is LiturgicalDay &&
      other.season == season &&
      other.color == color &&
      other.special == special &&
      other.sundayNumber == sundayNumber;

  @override
  int get hashCode => Object.hash(season, color, special, sundayNumber);

  @override
  String toString() =>
      'LiturgicalDay(${season.name}, ${color.name}, ${special?.name}, $sundayNumber)';
}

DateTime _day(int y, int m, int d) => DateTime.utc(y, m, d);
DateTime _plus(DateTime d, int days) => DateTime.utc(d.year, d.month, d.day + days);
int _daysBetween(DateTime a, DateTime b) => b.difference(a).inDays;

/// Easter Sunday of [year] (Gregorian computus, anonymous algorithm).
DateTime easterSunday(int year) {
  final a = year % 19, b = year ~/ 100, c = year % 100;
  final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return _day(year, month, day);
}

/// First Sunday of Advent of [year]: the fourth Sunday before Christmas.
DateTime firstSundayOfAdvent(int year) {
  final christmas = _day(year, 12, 25);
  return _plus(christmas, -(christmas.weekday % 7 == 0 ? 7 : christmas.weekday % 7) - 21);
}

/// The Epiphany of [year]: 6 January, or the Sunday between 2 and 8 January
/// where it is transferred.
DateTime epiphanyOf(int year, [CalendarRegion region = CalendarRegion.general]) {
  if (!region.sundayTransfers) return _day(year, 1, 6);
  final second = _day(year, 1, 2);
  return _plus(second, (7 - second.weekday % 7) % 7);
}

/// The Baptism of the Lord of [year]: the Sunday after the Epiphany, or the
/// Monday after it when a transferred Epiphany falls on 7 or 8 January.
DateTime baptismOfTheLord(int year, [CalendarRegion region = CalendarRegion.general]) {
  final epiphany = epiphanyOf(year, region);
  if (region.sundayTransfers) return _plus(epiphany, epiphany.day >= 7 ? 1 : 7);
  return _plus(epiphany, 7 - epiphany.weekday % 7);
}

/// The Ascension of [year]: Thursday, 40 days after Easter, or the next
/// Sunday (the 7th of Easter) where it is transferred.
DateTime ascensionOf(int year, [CalendarRegion region = CalendarRegion.general]) =>
    _plus(easterSunday(year), region.sundayTransfers ? 42 : 39);

/// Holy Family: the Sunday after Christmas, or 30 December if there is none.
DateTime holyFamily(int year) {
  for (var d = 26; d <= 31; d++) {
    if (_day(year, 12, d).weekday == DateTime.sunday) return _day(year, 12, d);
  }
  return _day(year, 12, 30);
}

/// Where [date] falls in the Church year (General Roman Calendar, with the
/// Sunday transfers of [region]).
LiturgicalDay liturgicalDay(DateTime date, [CalendarRegion region = CalendarRegion.general]) {
  final d = _day(date.year, date.month, date.day);
  final y = d.year;
  final sunday = d.weekday == DateTime.sunday;

  final easter = easterSunday(y);
  final ashWednesday = _plus(easter, -46);
  final pentecost = _plus(easter, 49);
  final advent = firstSundayOfAdvent(y);
  final christTheKing = _plus(advent, -7);
  final baptism = baptismOfTheLord(y, region);

  LiturgicalDay named(SpecialDay s, Season season, LiturgicalColor c) =>
      LiturgicalDay(season: season, color: c, special: s);
  int week(DateTime first) => _daysBetween(first, d) ~/ 7 + 1;

  // Christmas Time: 25 December – Baptism of the Lord (spans the new year).
  if (d.month == 12 && d.day >= 25 || !d.isAfter(baptism)) {
    const white = LiturgicalColor.white;
    if (d.month == 12 && d.day == 25) return named(SpecialDay.christmas, Season.christmas, white);
    if (d == holyFamily(y)) return named(SpecialDay.holyFamily, Season.christmas, white);
    if (d.month == 1 && d.day == 1) {
      return named(SpecialDay.maryMotherOfGod, Season.christmas, white);
    }
    if (d == epiphanyOf(y, region)) return named(SpecialDay.epiphany, Season.christmas, white);
    if (d == baptism) return named(SpecialDay.baptismOfTheLord, Season.christmas, white);
    return const LiturgicalDay(season: Season.christmas, color: white);
  }

  if (!d.isBefore(advent)) {
    final n = week(advent);
    return LiturgicalDay(
      season: Season.advent,
      color: sunday && n == 3 ? LiturgicalColor.rose : LiturgicalColor.violet,
      sundayNumber: sunday ? n : null,
    );
  }

  if (!d.isBefore(ashWednesday) && d.isBefore(easter)) {
    const violet = LiturgicalColor.violet;
    switch (_daysBetween(d, easter)) {
      case 46:
        return named(SpecialDay.ashWednesday, Season.lent, violet);
      case 7:
        return named(SpecialDay.palmSunday, Season.lent, LiturgicalColor.red);
      case 3:
        return named(SpecialDay.holyThursday, Season.lent, LiturgicalColor.white);
      case 2:
        return named(SpecialDay.goodFriday, Season.lent, LiturgicalColor.red);
      case 1:
        return named(SpecialDay.holySaturday, Season.lent, violet);
    }
    final n = week(_plus(ashWednesday, 4));
    return LiturgicalDay(
      season: Season.lent,
      color: sunday && n == 4 ? LiturgicalColor.rose : violet,
      sundayNumber: sunday ? n : null,
    );
  }

  if (!d.isBefore(easter) && !d.isAfter(pentecost)) {
    const white = LiturgicalColor.white;
    if (d == easter) return named(SpecialDay.easterSunday, Season.easter, white);
    if (d == ascensionOf(y, region)) return named(SpecialDay.ascension, Season.easter, white);
    if (d == pentecost) return named(SpecialDay.pentecost, Season.easter, LiturgicalColor.red);
    return LiturgicalDay(
      season: Season.easter,
      color: white,
      sundayNumber: sunday ? week(easter) : null,
    );
  }

  // Ordinary Time: after the Baptism until Lent, after Pentecost until Advent.
  const green = LiturgicalColor.green;
  if (d == _plus(pentecost, 7)) {
    return named(SpecialDay.trinitySunday, Season.ordinary, LiturgicalColor.white);
  }
  if (d == christTheKing) {
    return named(SpecialDay.christTheKing, Season.ordinary, LiturgicalColor.white);
  }
  if (!sunday) return const LiturgicalDay(season: Season.ordinary, color: green);
  // Counted from the Sunday of the Baptism's week (it may be kept on a Monday).
  final firstSunday = _plus(baptism, -(baptism.weekday % 7));
  final n = d.isBefore(ashWednesday) ? week(firstSunday) : 34 - _daysBetween(d, christTheKing) ~/ 7;
  return LiturgicalDay(season: Season.ordinary, color: green, sundayNumber: n);
}
