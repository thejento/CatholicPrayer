import 'package:flutter/material.dart';

import '../domain/liturgical_calendar.dart';
import '../domain/mysteries.dart';
import '../domain/sanctoral.dart';
import '../l10n/generated/app_localizations.dart';

const _englishOrdinals = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'];

/// "Second" (en), "II" (es, as in Spanish liturgical books), "2e" (fr).
String liturgicalOrdinal(int n, String lang) {
  switch (lang) {
    case 'es':
      const tens = ['', 'X', 'XX', 'XXX'];
      const units = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
      return tens[n ~/ 10] + units[n % 10];
    case 'fr':
      return n == 1 ? '1er' : '${n}e';
    default:
      if (n <= _englishOrdinals.length) return _englishOrdinals[n - 1];
      final suffix = (n % 100 >= 11 && n % 100 <= 13)
          ? 'th'
          : switch (n % 10) {
              1 => 'st',
              2 => 'nd',
              3 => 'rd',
              _ => 'th',
            };
      return '$n$suffix';
  }
}

String seasonName(AppLocalizations l10n, Season season) => switch (season) {
  Season.advent => l10n.seasonAdvent,
  Season.christmas => l10n.seasonChristmas,
  Season.lent => l10n.seasonLent,
  Season.easter => l10n.seasonEaster,
  Season.ordinary => l10n.seasonOrdinary,
};

/// "Second Sunday of Advent", "Ash Wednesday", "Ordinary Time".
String liturgicalDayName(AppLocalizations l10n, LiturgicalDay day, String lang) {
  if (day.special case final special?) {
    return switch (special) {
      SpecialDay.christmas => l10n.dayChristmas,
      SpecialDay.holyFamily => l10n.dayHolyFamily,
      SpecialDay.maryMotherOfGod => l10n.dayMaryMotherOfGod,
      SpecialDay.epiphany => l10n.dayEpiphany,
      SpecialDay.baptismOfTheLord => l10n.dayBaptismOfTheLord,
      SpecialDay.ashWednesday => l10n.dayAshWednesday,
      SpecialDay.palmSunday => l10n.dayPalmSunday,
      SpecialDay.holyThursday => l10n.dayHolyThursday,
      SpecialDay.goodFriday => l10n.dayGoodFriday,
      SpecialDay.holySaturday => l10n.dayHolySaturday,
      SpecialDay.easterSunday => l10n.dayEasterSunday,
      SpecialDay.ascension => l10n.dayAscension,
      SpecialDay.pentecost => l10n.dayPentecost,
      SpecialDay.trinitySunday => l10n.dayTrinitySunday,
      SpecialDay.christTheKing => l10n.dayChristTheKing,
    };
  }
  if (day.sundayNumber case final n?) {
    final ordinal = liturgicalOrdinal(n, lang);
    return switch (day.season) {
      Season.advent => l10n.sundayOfAdvent(ordinal),
      Season.lent => l10n.sundayOfLent(ordinal),
      Season.easter => l10n.sundayOfEaster(ordinal),
      _ => l10n.sundayInOrdinaryTime(ordinal),
    };
  }
  return seasonName(l10n, day.season);
}

/// The name of [date]'s place in the Church year.
String liturgicalDayNameFor(
  AppLocalizations l10n,
  DateTime date, [
  CalendarRegion region = CalendarRegion.general,
]) => liturgicalDayName(l10n, liturgicalDay(date, region), l10n.localeName);

/// The vestment colour of the day, for the small dot on the home screen.
Color liturgicalColor(LiturgicalColor color) => switch (color) {
  LiturgicalColor.violet => const Color(0xFF6A1B9A),
  LiturgicalColor.rose => const Color(0xFFE48AB0),
  LiturgicalColor.white => const Color(0xFFFFFFFF),
  LiturgicalColor.red => const Color(0xFFC62828),
  LiturgicalColor.green => const Color(0xFF2E7D32),
};

/// Why a Sunday suggests other mysteries than usual, or null.
String? sundayMysteriesNote(AppLocalizations l10n, DateTime date, LiturgicalDay day) {
  if (date.weekday != DateTime.sunday) return null;
  return switch (day.season) {
    Season.advent => l10n.sundayNoteAdvent,
    Season.christmas => l10n.sundayNoteChristmas,
    Season.lent => l10n.sundayNoteLent,
    _ => null,
  };
}

String rankName(AppLocalizations l10n, Rank rank) => switch (rank) {
  Rank.solemnity => l10n.rankSolemnity,
  Rank.feast => l10n.rankFeast,
  Rank.memorial => l10n.rankMemorial,
  Rank.optionalMemorial => l10n.rankOptionalMemorial,
};

String seasonAbout(AppLocalizations l10n, Season season) => switch (season) {
  Season.advent => l10n.aboutAdvent,
  Season.christmas => l10n.aboutChristmas,
  Season.lent => l10n.aboutLent,
  Season.easter => l10n.aboutEaster,
  Season.ordinary => l10n.aboutOrdinary,
};

String colorAbout(AppLocalizations l10n, LiturgicalColor color) => switch (color) {
  LiturgicalColor.violet => l10n.colorViolet,
  LiturgicalColor.rose => l10n.colorRose,
  LiturgicalColor.white => l10n.colorWhite,
  LiturgicalColor.red => l10n.colorRed,
  LiturgicalColor.green => l10n.colorGreen,
};

String setAbout(AppLocalizations l10n, MysterySet set) => switch (set) {
  MysterySet.joyful => l10n.aboutJoyful,
  MysterySet.luminous => l10n.aboutLuminous,
  MysterySet.sorrowful => l10n.aboutSorrowful,
  MysterySet.glorious => l10n.aboutGlorious,
};

String rankAbout(AppLocalizations l10n, Rank rank) => switch (rank) {
  Rank.solemnity => l10n.rankSolemnityAbout,
  Rank.feast => l10n.rankFeastAbout,
  Rank.memorial => l10n.rankMemorialAbout,
  Rank.optionalMemorial => l10n.rankOptionalMemorialAbout,
};

/// The liturgical colour as a small dot; decorative, the text names it.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
    );
  }
}

String calendarName(AppLocalizations l10n, CalendarRegion region) => switch (region) {
  CalendarRegion.general => l10n.calendarGeneral,
  CalendarRegion.canada => l10n.calendarCanada,
  CalendarRegion.unitedStates => l10n.calendarUnitedStates,
};
