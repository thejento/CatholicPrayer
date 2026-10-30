import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/audio/clips.dart';
import 'package:crc/src/domain/guidance.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final steps = buildRosarySequence();
  int countOf(StepKind kind) => steps.where((s) => s.kind == kind).length;

  group('buildRosarySequence', () {
    test('has 80 steps', () => expect(steps, hasLength(80)));

    test('has the traditional prayer counts', () {
      expect(countOf(StepKind.hailMary), 53);
      expect(countOf(StepKind.ourFather), 6);
      expect(countOf(StepKind.gloryBe), 6);
      expect(countOf(StepKind.fatimaPrayer), 5);
      expect(countOf(StepKind.announceMystery), 5);
      expect(countOf(StepKind.apostlesCreed), 1);
      expect(countOf(StepKind.signOfTheCross), 2);
      expect(countOf(StepKind.hailHolyQueen), 1);
      expect(countOf(StepKind.closingPrayer), 1);
    });

    test('starts and ends with the Sign of the Cross on the crucifix', () {
      expect(steps.first.kind, StepKind.signOfTheCross);
      expect(steps.first.part, RosaryPart.introduction);
      expect(steps.last.kind, StepKind.signOfTheCross);
      expect(steps.last.part, RosaryPart.closing);
      expect(steps.first.bead, crucifixBead);
      expect(steps.last.bead, crucifixBead);
    });

    test('introduction is Creed, Our Father, 3 Hail Marys, Glory Be', () {
      expect(steps.take(7).map((s) => s.kind), [
        StepKind.signOfTheCross,
        StepKind.apostlesCreed,
        StepKind.ourFather,
        StepKind.hailMary,
        StepKind.hailMary,
        StepKind.hailMary,
        StepKind.gloryBe,
      ]);
      expect(steps.sublist(3, 6).map((s) => s.count), [1, 2, 3]);
    });

    for (var d = 1; d <= 5; d++) {
      test('decade $d has announce, Our Father, 10 Hail Marys, Glory Be, Fatima', () {
        final decade = steps.where((s) => s.decade == d).toList();
        expect(decade, hasLength(14));
        expect(decade.first.kind, StepKind.announceMystery);
        expect(decade[1].kind, StepKind.ourFather);
        final hailMarys = decade.sublist(2, 12);
        expect(hailMarys.every((s) => s.kind == StepKind.hailMary), isTrue);
        expect(hailMarys.map((s) => s.count), List.generate(10, (i) => i + 1));
        expect(decade[12].kind, StepKind.gloryBe);
        expect(decade[13].kind, StepKind.fatimaPrayer);
      });
    }

    test('every Hail Mary is on a small bead and every Our Father on a large one', () {
      for (final s in steps) {
        if (s.kind == StepKind.hailMary) expect(beadKindAt(s.bead), BeadKind.small, reason: '$s');
        if (s.kind == StepKind.ourFather) expect(beadKindAt(s.bead), BeadKind.large, reason: '$s');
      }
    });

    test('each small bead is prayed exactly once', () {
      final smallBeads = steps
          .where((s) => s.kind == StepKind.hailMary)
          .map((s) => s.bead)
          .toList();
      expect(smallBeads.toSet(), hasLength(smallBeads.length));
      final allSmall = [
        for (var i = 0; i < beadCount; i++)
          if (beadKindAt(i) == BeadKind.small) i,
      ];
      expect(smallBeads.toSet(), allSmall.toSet());
    });

    test('Glory Be after a decade moves to the next large bead or the medal', () {
      final closers = steps.where((s) => s.part == RosaryPart.decade && s.kind == StepKind.gloryBe);
      expect(closers.map((s) => s.bead), [17, 28, 39, 50, medalBead]);
    });

    test('only mystery announcements have no prayer text', () {
      for (final s in steps) {
        expect(s.prayerId == null, s.kind == StepKind.announceMystery, reason: '$s');
      }
    });

    test('the sequence cannot be modified', () {
      expect(() => steps.add(steps.first), throwsUnsupportedError);
    });
  });

  group('Divine Mercy Chaplet (I-01)', () {
    final chaplet = buildDivineMercySequence();
    int count(StepKind kind) => chaplet.where((s) => s.kind == kind).length;

    test('has 63 steps: opening, five decades, Holy God three times, Sign of the Cross', () {
      expect(chaplet, hasLength(63));
      expect(chaplet.take(4).map((s) => s.kind), [
        StepKind.signOfTheCross,
        StepKind.ourFather,
        StepKind.hailMary,
        StepKind.apostlesCreed,
      ]);
      expect(count(StepKind.eternalFather), 5);
      expect(count(StepKind.sorrowfulPassion), 50);
      expect(count(StepKind.holyGod), 3);
      expect(chaplet.last.kind, StepKind.signOfTheCross);
      expect(chaplet.last.bead, crucifixBead);
      expect(chaplet.every((s) => s.devotion == Devotion.divineMercy), isTrue);
    });

    test('uses the Rosary beads: Eternal Father on the large ones, the decade on the small', () {
      for (final s in chaplet) {
        if (s.kind == StepKind.eternalFather) {
          expect(beadKindAt(s.bead), BeadKind.large);
          expect(s.bead, ourFatherBeadForDecade(s.decade!));
        }
        if (s.kind == StepKind.sorrowfulPassion) {
          expect(s.bead, hailMaryBead(s.decade!, s.count!));
        }
      }
      expect(chaplet.where((s) => s.kind == StepKind.holyGod).map((s) => s.bead).toSet(), {
        medalBead,
      });
    });

    test('has its own guidance and prayers', () {
      expect(chaplet.map(guidanceOf).nonNulls, hasLength(63));
      expect(guidanceOf(chaplet[2]), Guidance.chapletHailMary);
      expect(guidanceOf(chaplet[3]), Guidance.chapletCreed);
      expect(guidanceOf(chaplet[4]), Guidance.eternalFather);
      expect(guidanceOf(chaplet[5]), Guidance.sorrowfulPassion);
      expect(guidanceOf(chaplet[59]), Guidance.holyGod);
      expect(chaplet.map((s) => s.prayerId).toSet(), {
        'sign_of_the_cross',
        'our_father',
        'hail_mary',
        'apostles_creed',
        'divine_mercy_eternal_father',
        'divine_mercy_passion',
        'divine_mercy_holy_god',
      });
      expect(clipsForStep(chaplet[5], null, withGuidance: true), [
        'guide_sorrowfulPassion',
        'prayer_divine_mercy_passion',
      ]);
    });

    test('the Rosary is unchanged', () {
      expect(buildRosarySequence().every((s) => s.devotion == Devotion.rosary), isTrue);
    });
  });

  group('beadKindAt', () {
    test('has 1 crucifix, 1 medal, 6 large and 53 small beads', () {
      final kinds = [for (var i = 0; i < beadCount; i++) beadKindAt(i)];
      expect(kinds.where((k) => k == BeadKind.crucifix), hasLength(1));
      expect(kinds.where((k) => k == BeadKind.medal), hasLength(1));
      expect(kinds.where((k) => k == BeadKind.large), hasLength(6));
      expect(kinds.where((k) => k == BeadKind.small), hasLength(53));
    });

    test('rejects out-of-range indices', () {
      expect(() => beadKindAt(-1), throwsRangeError);
      expect(() => beadKindAt(beadCount), throwsRangeError);
    });
  });

  group('mysteries only', () {
    final steps = buildMysteriesOnlySequence();

    test('opening prayers, the five mysteries, closing prayers', () {
      expect(steps.map((s) => s.kind), [
        StepKind.openingPrayers,
        for (var d = 1; d <= 5; d++) StepKind.announceMystery,
        StepKind.closingPrayers,
      ]);
      expect(steps.where((s) => s.decade != null).map((s) => s.decade), [1, 2, 3, 4, 5]);
      expect(buildSequence(RosaryMode.mysteriesOnly), hasLength(7));
      expect(buildSequence(RosaryMode.guided), hasLength(80));
    });

    test('each mystery covers its decade; together they cover the rosary', () {
      for (final s in steps.where((s) => s.decade != null)) {
        expect(s.bead, ourFatherBeadForDecade(s.decade!));
        expect(s.covers, [for (var h = 1; h <= 10; h++) hailMaryBead(s.decade!, h)]);
      }
      final all = {
        for (final s in steps) ...[s.bead, ...s.covers],
      };
      expect(all, {for (var b = 0; b < beadCount; b++) b});
    });

    test('summary cards have no prayer, guidance or clip of their own', () {
      for (final s in [steps.first, steps.last]) {
        expect(s.prayerId, isNull);
        expect(guidanceOf(s), isNull);
        expect(clipsForStep(s, MysterySet.joyful, withGuidance: true), isEmpty);
      }
    });
  });
}
