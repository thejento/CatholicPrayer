/// A single prayer in the app's registry (e.g. the Our Father, Hail Mary,
/// or Rosary-specific prayers), with its title and text keyed by locale.
class Prayer {
  const Prayer({
    required this.id,
    required this.title,
    required this.text,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as String,
      title: Map<String, String>.from(json['title'] as Map),
      text: Map<String, String>.from(json['text'] as Map),
    );
  }

  final String id;
  final Map<String, String> title;
  final Map<String, String> text;

  /// Returns the localized title, falling back to English then to any
  /// available translation if the requested [languageCode] is missing.
  String titleFor(String languageCode) => _localize(title, languageCode);

  /// Returns the localized prayer text, falling back the same way as
  /// [titleFor].
  String textFor(String languageCode) => _localize(text, languageCode);

  static String _localize(Map<String, String> values, String languageCode) {
    return values[languageCode] ??
        values['en'] ??
        (values.isNotEmpty ? values.values.first : '');
  }
}
