import '../data/content_repository.dart';
import '../domain/guidance.dart';
import '../domain/mysteries.dart';
import '../domain/rosary_sequence.dart';

/// Ids of the pre-rendered audio clips (DESIGN §3.7). One file per id and
/// language: `assets/audio/<lang>/<id>.mp3`.
String prayerClip(String prayerId) => 'prayer_$prayerId';
String mysteryClip(MysterySet set, int decade) => 'mystery_${set.name}_$decade';
String guidanceClip(Guidance guidance) => 'guide_${guidance.name}';

/// Clips to play, in order, for [step]: the instruction (when wanted), then
/// the prayer or mystery announcement.
List<String> clipsForStep(RosaryStep step, MysterySet set, {required bool withGuidance}) => [
  if (withGuidance) guidanceClip(guidanceOf(step)),
  if (step.prayerId case final id?) prayerClip(id) else mysteryClip(set, step.decade!),
];

/// Every clip's spoken text for [lang]. This is the single source of truth
/// that the render tool reads and the freshness test checks.
///
/// [guidance] gives the localized text of each [Guidance] instruction.
Map<String, String> speakableTexts(
  ContentRepository content,
  String lang,
  String Function(Guidance) guidance,
) {
  final prayerIds = buildRosarySequence().map((s) => s.prayerId).nonNulls.toSet();
  return {
    for (final id in prayerIds) prayerClip(id): spokenPrayer(content.prayer(id)!.textFor(lang)),
    for (final set in MysterySet.values)
      for (final m in content.mysteriesOf(set))
        mysteryClip(set, m.number):
            '${content.mysterySetTitle(set).of(lang)}. '
            '${content.ordinal(m.number).of(lang)}: ${m.title.of(lang)}.',
    for (final g in Guidance.values) guidanceClip(g): guidance(g),
  };
}

/// Prepares prayer text for speech: drops the V./R. (versicle/response)
/// markers and joins paragraphs.
String spokenPrayer(String text) => text
    .split('\n')
    .map((line) => line.replaceFirst(RegExp(r'^[VR]\.\s*'), '').trim())
    .where((line) => line.isNotEmpty)
    .join(' ');
