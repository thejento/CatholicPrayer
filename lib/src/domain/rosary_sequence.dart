import 'mysteries.dart';

/// What the person praying does at a given step.
enum StepKind {
  signOfTheCross,
  apostlesCreed,
  ourFather,
  hailMary,
  gloryBe,
  announceMystery,
  fatimaPrayer,
  hailHolyQueen,
  closingPrayer,

  /// Mysteries-only mode: one card each for the prayers before the first
  /// decade and after the last (DESIGN §3.15).
  openingPrayers,
  closingPrayers,

  /// Divine Mercy Chaplet (I-01, DESIGN §3.22).
  eternalFather,
  sorrowfulPassion,
  holyGod,
}

/// What is prayed on the beads: the Rosary, or a chaplet that uses the same
/// rosary beads (I-01).
enum Devotion { rosary, divineMercy }

/// Guided: every prayer, one step per bead (80 steps). Mysteries only: the
/// opening prayers, the five mysteries and the closing prayers (7 steps), for
/// people who know the prayers (DESIGN §3.15).
enum RosaryMode { guided, mysteriesOnly }

/// Prayers summarised by the [StepKind.openingPrayers] card, in order.
const openingPrayerIds = [
  'sign_of_the_cross',
  'apostles_creed',
  'our_father',
  'hail_mary',
  'glory_be',
];

/// Prayers summarised by the [StepKind.closingPrayers] card, in order.
const closingPrayerIds = ['hail_holy_queen', 'rosary_closing_prayer', 'sign_of_the_cross'];

/// The three parts of the Rosary, used to tailor guidance and labels.
enum RosaryPart { introduction, decade, closing }

/// The kind of physical object at a bead position.
enum BeadKind { crucifix, large, small, medal }

/// Total number of bead positions: crucifix, 5 pendant beads, the medal and
/// a loop of 4 large and 50 small beads. See docs/DESIGN.md §4.2.
const int beadCount = 61;

/// Bead index of the crucifix.
const int crucifixBead = 0;

/// Bead index of the centre medal joining the pendant to the loop.
const int medalBead = 6;

const Set<int> _largeBeads = {1, 5, 17, 28, 39, 50};

BeadKind beadKindAt(int index) {
  RangeError.checkValueInInterval(index, 0, beadCount - 1, 'index');
  if (index == crucifixBead) return BeadKind.crucifix;
  if (index == medalBead) return BeadKind.medal;
  if (_largeBeads.contains(index)) return BeadKind.large;
  return BeadKind.small;
}

/// Large bead on which the Our Father of [decade] (1-5) is prayed.
int ourFatherBeadForDecade(int decade) => decade == 1 ? 5 : 6 + (decade - 1) * 11;

/// Small bead for the [hailMary]-th (1-10) Hail Mary of [decade] (1-5).
int hailMaryBead(int decade, int hailMary) => 7 + (decade - 1) * 11 + (hailMary - 1);

/// One step of the guided Rosary.
class RosaryStep {
  const RosaryStep({
    required this.kind,
    required this.part,
    required this.bead,
    this.decade,
    this.count,
    this.covers = const [],
    this.devotion = Devotion.rosary,
  });

  final StepKind kind;
  final RosaryPart part;

  /// Bead to highlight, from 0 to [beadCount] - 1.
  final int bead;

  /// Decade number (1-5) for steps that belong to, or close, a decade.
  final int? decade;

  /// Position of a Hail Mary within its group (1-3 in the introduction,
  /// 1-10 in a decade).
  final int? count;

  /// Further beads this step stands for (mysteries only: the whole decade).
  final List<int> covers;

  final Devotion devotion;

  /// Id of the prayer said at this step, or `null` for a mystery
  /// announcement (which has no fixed text).
  String? get prayerId => switch (kind) {
    StepKind.signOfTheCross => 'sign_of_the_cross',
    StepKind.apostlesCreed => 'apostles_creed',
    StepKind.ourFather => 'our_father',
    StepKind.hailMary => 'hail_mary',
    StepKind.gloryBe => 'glory_be',
    StepKind.fatimaPrayer => 'fatima_prayer',
    StepKind.hailHolyQueen => 'hail_holy_queen',
    StepKind.closingPrayer => 'rosary_closing_prayer',
    StepKind.eternalFather => 'divine_mercy_eternal_father',
    StepKind.sorrowfulPassion => 'divine_mercy_passion',
    StepKind.holyGod => 'divine_mercy_holy_god',
    StepKind.announceMystery || StepKind.openingPrayers || StepKind.closingPrayers => null,
  };

  @override
  String toString() =>
      'RosaryStep($kind, $part, bead: $bead, '
      'decade: $decade, count: $count)';
}

/// Builds the 80-step Rosary described in docs/DESIGN.md §4.1.
List<RosaryStep> buildRosarySequence() {
  const intro = RosaryPart.introduction;
  final steps = <RosaryStep>[
    const RosaryStep(kind: StepKind.signOfTheCross, part: intro, bead: crucifixBead),
    const RosaryStep(kind: StepKind.apostlesCreed, part: intro, bead: crucifixBead),
    const RosaryStep(kind: StepKind.ourFather, part: intro, bead: 1),
    for (var i = 1; i <= 3; i++)
      RosaryStep(kind: StepKind.hailMary, part: intro, bead: 1 + i, count: i),
    const RosaryStep(kind: StepKind.gloryBe, part: intro, bead: 5),
  ];

  for (var d = 1; d <= mysteriesPerSet; d++) {
    const part = RosaryPart.decade;
    final ofBead = ourFatherBeadForDecade(d);
    // The Glory Be and Fatima Prayer move to the next large bead (or the
    // medal after the last decade) to show the decade is complete.
    final closingBead = d < mysteriesPerSet ? ourFatherBeadForDecade(d + 1) : medalBead;
    steps.addAll([
      RosaryStep(kind: StepKind.announceMystery, part: part, bead: ofBead, decade: d),
      RosaryStep(kind: StepKind.ourFather, part: part, bead: ofBead, decade: d),
      for (var h = 1; h <= 10; h++)
        RosaryStep(
          kind: StepKind.hailMary,
          part: part,
          bead: hailMaryBead(d, h),
          decade: d,
          count: h,
        ),
      RosaryStep(kind: StepKind.gloryBe, part: part, bead: closingBead, decade: d),
      RosaryStep(kind: StepKind.fatimaPrayer, part: part, bead: closingBead, decade: d),
    ]);
  }

  const closing = RosaryPart.closing;
  steps.addAll(const [
    RosaryStep(kind: StepKind.hailHolyQueen, part: closing, bead: medalBead),
    RosaryStep(kind: StepKind.closingPrayer, part: closing, bead: medalBead),
    RosaryStep(kind: StepKind.signOfTheCross, part: closing, bead: crucifixBead),
  ]);
  return List.unmodifiable(steps);
}

/// Builds the 7-step mysteries-only Rosary described in docs/DESIGN.md §3.15.
List<RosaryStep> buildMysteriesOnlySequence() => List.unmodifiable([
  RosaryStep(
    kind: StepKind.openingPrayers,
    part: RosaryPart.introduction,
    bead: crucifixBead,
    covers: [for (var b = 1; b < medalBead; b++) b],
  ),
  for (var d = 1; d <= mysteriesPerSet; d++)
    RosaryStep(
      kind: StepKind.announceMystery,
      part: RosaryPart.decade,
      bead: ourFatherBeadForDecade(d),
      decade: d,
      covers: [for (var h = 1; h <= 10; h++) hailMaryBead(d, h)],
    ),
  const RosaryStep(kind: StepKind.closingPrayers, part: RosaryPart.closing, bead: medalBead),
]);

List<RosaryStep> buildSequence(RosaryMode mode) => switch (mode) {
  RosaryMode.guided => buildRosarySequence(),
  RosaryMode.mysteriesOnly => buildMysteriesOnlySequence(),
};

/// Builds the 63-step Divine Mercy Chaplet, prayed on the same beads as the
/// Rosary (DESIGN §3.22): Our Father, Hail Mary and Creed on the first beads,
/// then on each decade the Eternal Father and ten times "For the sake of His
/// sorrowful Passion", and "Holy God" three times on the medal.
List<RosaryStep> buildDivineMercySequence() {
  const dm = Devotion.divineMercy;
  const intro = RosaryPart.introduction;
  const closing = RosaryPart.closing;
  return List.unmodifiable([
    const RosaryStep(kind: StepKind.signOfTheCross, part: intro, bead: crucifixBead, devotion: dm),
    const RosaryStep(kind: StepKind.ourFather, part: intro, bead: 1, devotion: dm),
    const RosaryStep(kind: StepKind.hailMary, part: intro, bead: 2, devotion: dm),
    const RosaryStep(kind: StepKind.apostlesCreed, part: intro, bead: 3, devotion: dm),
    for (var d = 1; d <= mysteriesPerSet; d++) ...[
      RosaryStep(
        kind: StepKind.eternalFather,
        part: RosaryPart.decade,
        bead: ourFatherBeadForDecade(d),
        decade: d,
        devotion: dm,
      ),
      for (var h = 1; h <= 10; h++)
        RosaryStep(
          kind: StepKind.sorrowfulPassion,
          part: RosaryPart.decade,
          bead: hailMaryBead(d, h),
          decade: d,
          count: h,
          devotion: dm,
        ),
    ],
    for (var i = 1; i <= 3; i++)
      RosaryStep(kind: StepKind.holyGod, part: closing, bead: medalBead, count: i, devotion: dm),
    const RosaryStep(
      kind: StepKind.signOfTheCross,
      part: closing,
      bead: crucifixBead,
      devotion: dm,
    ),
  ]);
}
