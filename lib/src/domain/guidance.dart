import 'mysteries.dart';
import 'rosary_sequence.dart';

/// The "what to do" instruction shown (and optionally spoken) for a step.
/// The text lives in the ARB files as `guide<Name>`; see `ui/step_text.dart`.
enum Guidance {
  signOfCrossStart,
  creed,
  ourFatherIntro,
  hailMaryFaith,
  hailMaryHope,
  hailMaryCharity,
  gloryBeIntro,
  announce,
  ourFatherDecade,
  hailMaryDecade,
  gloryBeDecade,
  gloryBeLastDecade,
  fatima,
  hailHolyQueen,
  closingPrayer,
  ourFatherHolyFather,
  hailMaryHolyFather,
  gloryBeHolyFather,
  saintMichael,
  signOfCrossEnd,
}

/// Which instruction applies to [step] (see DESIGN §3.2); none for the
/// mysteries-only summary cards.
Guidance? guidanceOf(RosaryStep step) {
  final intro = step.part == RosaryPart.introduction;
  final closing = step.part == RosaryPart.closing;
  return switch (step.kind) {
    StepKind.signOfTheCross => closing ? Guidance.signOfCrossEnd : Guidance.signOfCrossStart,
    StepKind.apostlesCreed => Guidance.creed,
    // For the Holy Father's intentions, after the closing prayer.
    StepKind.ourFather when closing => Guidance.ourFatherHolyFather,
    StepKind.hailMary when closing => Guidance.hailMaryHolyFather,
    StepKind.gloryBe when closing => Guidance.gloryBeHolyFather,
    StepKind.ourFather => intro ? Guidance.ourFatherIntro : Guidance.ourFatherDecade,
    StepKind.hailMary when intro => switch (step.count) {
      1 => Guidance.hailMaryFaith,
      2 => Guidance.hailMaryHope,
      _ => Guidance.hailMaryCharity,
    },
    StepKind.hailMary => Guidance.hailMaryDecade,
    StepKind.gloryBe when intro => Guidance.gloryBeIntro,
    StepKind.gloryBe =>
      step.decade == mysteriesPerSet ? Guidance.gloryBeLastDecade : Guidance.gloryBeDecade,
    StepKind.announceMystery => Guidance.announce,
    StepKind.fatimaPrayer => Guidance.fatima,
    StepKind.hailHolyQueen => Guidance.hailHolyQueen,
    StepKind.closingPrayer => Guidance.closingPrayer,
    StepKind.saintMichael => Guidance.saintMichael,
    StepKind.openingPrayers || StepKind.closingPrayers => null,
  };
}
