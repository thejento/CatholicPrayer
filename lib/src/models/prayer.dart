import 'localized_text.dart';

/// A single prayer in the app's registry (e.g. the Our Father, Hail Mary,
/// or Rosary-specific prayers), with its title and text keyed by locale.
class Prayer {
  const Prayer({required this.id, required this.title, required this.text});

  final String id;
  final LocalizedText title;
  final LocalizedText text;

  /// Returns the localized title, falling back to English then to any
  /// available translation if the requested [languageCode] is missing.
  String titleFor(String languageCode) => title.of(languageCode);

  /// Returns the localized prayer text, falling back the same way as
  /// [titleFor].
  String textFor(String languageCode) => text.of(languageCode);
}
