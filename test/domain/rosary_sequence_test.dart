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

  group('optional ending (F-23)', () {
    List<StepKind> lastKinds(RosaryEnding ending, int n) {
      final all = buildRosarySequence(ending: ending);
      return all.skip(all.length - n).map((s) => s.kind).toList();
    }

    test('off by default: the 80 steps are unchanged', () {
      expect(buildRosarySequence(ending: const RosaryEnding()), hasLength(80));
      expect(lastKinds(const RosaryEnding(), 3), [
        StepKind.hailHolyQueen,
        StepKind.closingPrayer,
        StepKind.signOfTheCross,
      ]);
    });

    test("the Holy Father's intentions add an Our Father, a Hail Mary and a Glory Be", () {
      const ending = RosaryEnding(holyFather: true);
      expect(buildRosarySequence(ending: ending), hasLength(83));
      expect(lastKinds(ending, 5), [
        StepKind.closingPrayer,
        StepKind.ourFather,
        StepKind.hailMary,
        StepKind.gloryBe,
        StepKind.signOfTheCross,
      ]);
      final added = buildRosarySequence(ending: ending).skip(79).take(3);
      expect(added.map(guidanceOf), [
        Guidance.ourFatherHolyFather,
        Guidance.hailMaryHolyFather,
        Guidance.gloryBeHolyFather,
      ]);
      expect(added.every((s) => s.part == RosaryPart.closing && s.bead == medalBead), isTrue);
    });

    test('Saint Michael comes last, before the Sign of the Cross', () {
      expect(lastKinds(const RosaryEnding(saintMichael: true), 2), [
        StepKind.saintMichael,
        StepKind.signOfTheCross,
      ]);
      final all = buildRosarySequence(ending: RosaryEnding.all);
      expect(all, hasLength(84));
      final michael = all[all.length - 2];
      expect(michael.prayerId, 'saint_michael');
      expect(guidanceOf(michael), Guidance.saintMichael);
      expect(clipsForStep(michael, MysterySet.joyful, withGuidance: true), [
        'guide_saintMichael',
        'prayer_saint_michael',
      ]);
    });

    test('mysteries only lists the chosen prayers on the closing card', () {
      expect(buildMysteriesOnlySequence().last.summary, closingPrayerIds());
      expect(buildSequence(RosaryMode.mysteriesOnly, ending: RosaryEnding.all), hasLength(7));
      expect(buildSequence(RosaryMode.mysteriesOnly, ending: RosaryEnding.all).last.summary, [
        'hail_holy_queen',
        'rosary_closing_prayer',
        'holy_father_intentions',
        'saint_michael',
        'sign_of_the_cross',
      ]);
    });

    test('compares by value', () {
      expect(const RosaryEnding(holyFather: true), const RosaryEnding(holyFather: true));
      expect(const RosaryEnding(holyFather: true).hashCode, isNot(RosaryEnding.all.hashCode));
      expect(const RosaryEnding(), isNot(const RosaryEnding(saintMichael: true)));
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
