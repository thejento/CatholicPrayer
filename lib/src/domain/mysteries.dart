/// The four sets of mysteries meditated upon while praying the Rosary.
enum MysterySet { joyful, luminous, sorrowful, glorious }

/// Number of mysteries (and therefore decades) in each set.
const int mysteriesPerSet = 5;

/// Returns the set traditionally prayed on [date]'s weekday, following
/// *Rosarium Virginis Mariae* (2002): Monday and Saturday Joyful, Tuesday and
/// Friday Sorrowful, Wednesday and Sunday Glorious, Thursday Luminous.
MysterySet suggestedMysterySet(DateTime date) {
  switch (date.weekday) {
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
