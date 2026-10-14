import 'package:flutter/widgets.dart';

import '../domain/mysteries.dart';
import '../domain/rosary_sequence.dart';
import '../l10n/generated/app_localizations.dart';

/// The "what to do" sentence shown for [step] (see DESIGN §3.2).
String guidanceFor(AppLocalizations l10n, RosaryStep step) {
  final intro = step.part == RosaryPart.introduction;
  return switch (step.kind) {
    StepKind.signOfTheCross =>
      step.part == RosaryPart.closing ? l10n.guideSignOfCrossEnd : l10n.guideSignOfCrossStart,
    StepKind.apostlesCreed => l10n.guideCreed,
    StepKind.ourFather => intro ? l10n.guideOurFatherIntro : l10n.guideOurFatherDecade,
    StepKind.hailMary when intro => switch (step.count) {
      1 => l10n.guideHailMaryFaith,
      2 => l10n.guideHailMaryHope,
      _ => l10n.guideHailMaryCharity,
    },
    StepKind.hailMary => l10n.guideHailMaryDecade,
    StepKind.gloryBe when intro => l10n.guideGloryBeIntro,
    StepKind.gloryBe =>
      step.decade == mysteriesPerSet ? l10n.guideGloryBeLastDecade : l10n.guideGloryBeDecade,
    StepKind.announceMystery => l10n.guideAnnounce,
    StepKind.fatimaPrayer => l10n.guideFatima,
    StepKind.hailHolyQueen => l10n.guideHailHolyQueen,
    StepKind.closingPrayer => l10n.guideClosingPrayer,
  };
}

/// Short "where am I" label, e.g. "Decade 3 of 5".
String partLabel(AppLocalizations l10n, RosaryStep step) => switch (step.part) {
  RosaryPart.introduction => l10n.partIntroduction,
  RosaryPart.decade => l10n.decadeLabel(step.decade!),
  RosaryPart.closing => l10n.partClosing,
};

/// Language code used to pick devotional content for [context].
String contentLanguage(BuildContext context) => Localizations.localeOf(context).languageCode;
