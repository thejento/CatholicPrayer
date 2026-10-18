import 'liturgical_calendar.dart';

/// The four sets of mysteries meditated upon while praying the Rosary.
enum MysterySet { joyful, luminous, sorrowful, glorious }

/// Number of mysteries (and therefore decades) in each set.
const int mysteriesPerSet = 5;

/// Returns the set traditionally prayed on [date], following *Rosarium
/// Virginis Mariae* (2002): Monday and Saturday Joyful, Tuesday and Friday
/// Sorrowful, Wednesday and Sunday Glorious, Thursday Luminous. Sundays follow
/// the season: Joyful in Advent and Christmas Time, Sorrowful in Lent (§3.10).
MysterySet suggestedMysterySet(DateTime date) {
  switch (date.weekday) {
    case DateTime.sunday:
      return switch (liturgicalDay(date).season) {
        Season.advent || Season.christmas => MysterySet.joyful,
        Season.lent => MysterySet.sorrowful,
        _ => MysterySet.glorious,
      };
    case DateTime.monday:
    case DateTime.saturday:
      return MysterySet.joyful;
    case DateTime.tuesday:
    case DateTime.friday:
      return MysterySet.sorrowful;
    case DateTime.thursday:
      return MysterySet.luminous;
    default:
      return MysterySet.glorious;
  }
}
