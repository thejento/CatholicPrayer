import 'dart:ui';

import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/ui/widgets/rosary_beads.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sizes the drawing gets on phone, tablet, TV and very wide windows.
  const sizes = [Size(400, 256), Size(376, 508), Size(352, 504), Size(352, 412), Size(800, 300)];

  for (final size in sizes) {
    test('whole rosary fits in $size', () {
      final pos = beadPositions(size);
      expect(pos, hasLength(beadCount));
      final rect = Offset.zero & size;
      for (final p in pos) {
        expect(rect.contains(p), isTrue, reason: '$p outside $size');
      }
      // The cross extends ~0.2 r below the crucifix bead position.
      final spacing = (pos[1] - pos[0]).distance;
      expect(pos[crucifixBead].dy + spacing, lessThanOrEqualTo(size.height));
    });
  }
}
