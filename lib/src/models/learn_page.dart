import '../domain/mysteries.dart';
import 'localized_text.dart';

/// The topics of "Learn about the Rosary" (DESIGN §3.23), in display order.
enum LearnTopic {
  rosary('rosary'),
  joyful('joyful'),
  luminous('luminous'),
  sorrowful('sorrowful'),
  glorious('glorious'),
  divineMercy('divine-mercy'),
  ways('ways'),
  ending('ending');

  const LearnTopic(this.slug);

  /// Its part of the address: `#/learn/divine-mercy`.
  final String slug;

  static LearnTopic? fromSlug(String? slug) => values.where((t) => t.slug == slug).firstOrNull;

  static LearnTopic forSet(MysterySet set) => values.byName(set.name);

  /// The set of mysteries this topic explains, if any.
  MysterySet? get mysterySet => MysterySet.values.where((s) => s.name == name).firstOrNull;
}

/// One heading and its paragraph.
class LearnSection {
  const LearnSection({required this.heading, required this.text});

  final LocalizedText heading;
  final LocalizedText text;
}

/// A page that teaches one topic. The texts are the app's own writing.
class LearnPage {
  const LearnPage({required this.title, required this.summary, required this.sections});

  final LocalizedText title;

  /// One line, shown in lists and on the mystery cards.
  final LocalizedText summary;
  final List<LearnSection> sections;
}
