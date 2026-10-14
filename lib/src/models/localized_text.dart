/// A piece of text available in several languages, keyed by language code.
class LocalizedText {
  const LocalizedText(this.values);

  final Map<String, String> values;

  /// Returns the text for [languageCode], falling back to English and then
  /// to any available translation.
  String of(String languageCode) =>
      values[languageCode] ?? values['en'] ?? (values.isNotEmpty ? values.values.first : '');

  bool hasLanguage(String languageCode) => (values[languageCode] ?? '').trim().isNotEmpty;
}
