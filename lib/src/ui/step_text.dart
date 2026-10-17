import 'package:flutter/widgets.dart';

import '../domain/guidance.dart';
import '../domain/rosary_sequence.dart';
import '../l10n/generated/app_localizations.dart';

/// The "what to do" sentence shown for [step] (see DESIGN §3.2).
String guidanceFor(AppLocalizations l10n, RosaryStep step) => guidanceText(l10n, guidanceOf(step));

/// Localized text of a [Guidance] instruction.
String guidanceText(AppLocalizations l10n, Guidance guidance) => switch (guidance) {
  Guidance.signOfCrossStart => l10n.guideSignOfCrossStart,
  Guidance.creed => l10n.guideCreed,
  Guidance.ourFatherIntro => l10n.guideOurFatherIntro,
  Guidance.hailMaryFaith => l10n.guideHailMaryFaith,
  Guidance.hailMaryHope => l10n.guideHailMaryHope,
  Guidance.hailMaryCharity => l10n.guideHailMaryCharity,
  Guidance.gloryBeIntro => l10n.guideGloryBeIntro,
  Guidance.announce => l10n.guideAnnounce,
  Guidance.ourFatherDecade => l10n.guideOurFatherDecade,
  Guidance.hailMaryDecade => l10n.guideHailMaryDecade,
  Guidance.gloryBeDecade => l10n.guideGloryBeDecade,
  Guidance.gloryBeLastDecade => l10n.guideGloryBeLastDecade,
  Guidance.fatima => l10n.guideFatima,
  Guidance.hailHolyQueen => l10n.guideHailHolyQueen,
  Guidance.closingPrayer => l10n.guideClosingPrayer,
  Guidance.signOfCrossEnd => l10n.guideSignOfCrossEnd,
};

/// Short "where am I" label, e.g. "Decade 3 of 5".
String partLabel(AppLocalizations l10n, RosaryStep step) => switch (step.part) {
  RosaryPart.introduction => l10n.partIntroduction,
  RosaryPart.decade => l10n.decadeLabel(step.decade!),
  RosaryPart.closing => l10n.partClosing,
};

/// Language code used to pick devotional content for [context].
String contentLanguage(BuildContext context) => Localizations.localeOf(context).languageCode;
