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
  saintMichael,

  /// Mysteries-only mode: one card each for the prayers before the first
  /// decade and after the last (DESIGN §3.15).
  openingPrayers,
  closingPrayers,
}

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

/// Optional prayers after the closing prayer, before the last Sign of the
/// Cross (DESIGN §3.19). Both are off by default.
class RosaryEnding {
  const RosaryEnding({this.holyFather = false, this.saintMichael = false});

  /// Every option on: the longest Rosary, for the voice clips.
  static const all = RosaryEnding(holyFather: true, saintMichael: true);

  /// An Our Father, a Hail Mary and a Glory Be for the Pope's intentions.
  final bool holyFather;

  /// The prayer to Saint Michael the Archangel.
  final bool saintMichael;

  @override
  bool operator ==(Object other) =>
      other is RosaryEnding && other.holyFather == holyFather && other.saintMichael == saintMichael;

  @override
  int get hashCode => Object.hash(holyFather, saintMichael);
}

/// Prayers summarised by the [StepKind.closingPrayers] card, in order.
List<String> closingPrayerIds([RosaryEnding ending = const RosaryEnding()]) => [
  'hail_holy_queen',
  'rosary_closing_prayer',
  if (ending.holyFather) 'holy_father_intentions',
  if (ending.saintMichael) 'saint_michael',
  'sign_of_the_cross',
];

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
    this.summary = const [],
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

  /// Prayers listed on a mysteries-only summary card, in order.
  final List<String> summary;

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
    StepKind.saintMichael => 'saint_michael',
    StepKind.announceMystery || StepKind.openingPrayers || StepKind.closingPrayers => null,
  };

  @override
  String toString() =>
      'RosaryStep($kind, $part, bead: $bead, '
      'decade: $decade, count: $count)';
}

/// Builds the 80-step Rosary described in docs/DESIGN.md §4.1, with the
/// optional prayers of [ending] before the last Sign of the Cross.
List<RosaryStep> buildRosarySequence({RosaryEnding ending = const RosaryEnding()}) {
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
  steps.addAll([
    const RosaryStep(kind: StepKind.hailHolyQueen, part: closing, bead: medalBead),
    const RosaryStep(kind: StepKind.closingPrayer, part: closing, bead: medalBead),
    if (ending.holyFather) ...const [
      RosaryStep(kind: StepKind.ourFather, part: closing, bead: medalBead),
      RosaryStep(kind: StepKind.hailMary, part: closing, bead: medalBead),
      RosaryStep(kind: StepKind.gloryBe, part: closing, bead: medalBead),
    ],
    if (ending.saintMichael)
      const RosaryStep(kind: StepKind.saintMichael, part: closing, bead: medalBead),
    const RosaryStep(kind: StepKind.signOfTheCross, part: closing, bead: crucifixBead),
  ]);
  return List.unmodifiable(steps);
}

/// Builds the 7-step mysteries-only Rosary described in docs/DESIGN.md §3.15.
List<RosaryStep> buildMysteriesOnlySequence({RosaryEnding ending = const RosaryEnding()}) =>
    List.unmodifiable([
      RosaryStep(
        kind: StepKind.openingPrayers,
        part: RosaryPart.introduction,
        bead: crucifixBead,
        covers: [for (var b = 1; b < medalBead; b++) b],
        summary: openingPrayerIds,
      ),
      for (var d = 1; d <= mysteriesPerSet; d++)
        RosaryStep(
          kind: StepKind.announceMystery,
          part: RosaryPart.decade,
          bead: ourFatherBeadForDecade(d),
          decade: d,
          covers: [for (var h = 1; h <= 10; h++) hailMaryBead(d, h)],
        ),
      RosaryStep(
        kind: StepKind.closingPrayers,
        part: RosaryPart.closing,
        bead: medalBead,
        summary: closingPrayerIds(ending),
      ),
    ]);

List<RosaryStep> buildSequence(RosaryMode mode, {RosaryEnding ending = const RosaryEnding()}) =>
    switch (mode) {
      RosaryMode.guided => buildRosarySequence(ending: ending),
      RosaryMode.mysteriesOnly => buildMysteriesOnlySequence(ending: ending),
    };
