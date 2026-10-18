/// Vatican News, the Holy See's news service, has a "Saint of the day" page
/// for each date (DESIGN §3.11). Checked with tool/saints/check_vatican_links.py.
const _pages = {
  'en': 'https://www.vaticannews.va/en/saints/',
  'es': 'https://www.vaticannews.va/es/santos/',
  'fr': 'https://www.vaticannews.va/fr/saint-du-jour/',
};

const _index = {
  'en': 'https://www.vaticannews.va/en/saints.html',
  'es': 'https://www.vaticannews.va/es/santos.html',
  'fr': 'https://www.vaticannews.va/fr/saint-du-jour.html',
};

/// Dates (MM/DD) without a page; the saints index is linked instead.
const missingSaintPages = {
  'en': {'02/29', '11/01', '11/02'},
};

/// The Vatican News page about the saint of [date], in [lang] or else English.
Uri saintOfTheDayUrl(DateTime date, String lang) {
  final l = _pages.containsKey(lang) ? lang : 'en';
  final md = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  if (missingSaintPages[l]?.contains(md) ?? false) return Uri.parse(_index[l]!);
  return Uri.parse('${_pages[l]}$md.html');
}
