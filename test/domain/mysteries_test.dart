import 'package:crc/src/domain/mysteries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('suggestedMysterySet', () {
    // 2026-10-12 is a Monday.
    final expected = {
      DateTime(2026, 10, 12): MysterySet.joyful, // Monday
      DateTime(2026, 10, 13): MysterySet.sorrowful, // Tuesday
      DateTime(2026, 10, 14): MysterySet.glorious, // Wednesday
      DateTime(2026, 10, 15): MysterySet.luminous, // Thursday
      DateTime(2026, 10, 16): MysterySet.sorrowful, // Friday
      DateTime(2026, 10, 17): MysterySet.joyful, // Saturday
      DateTime(2026, 10, 18): MysterySet.glorious, // Sunday
    };
    expected.forEach((date, set) {
      test('weekday ${date.weekday} → ${set.name}', () {
        expect(suggestedMysterySet(date), set);
      });
    });

    test('every set is suggested at least once a week', () {
      expect(expected.values.toSet(), MysterySet.values.toSet());
    });
  });
}
