import 'dart:convert';

import 'package:flutter/services.dart';

import 'content_repository.dart';

/// Names of the celebrations of the General Roman Calendar (DESIGN §3.11),
/// from `assets/data/saints/<lang>.json`.
class SaintsRepository {
  SaintsRepository.fromJson(Map<String, Map<String, dynamic>> files)
    : _names = {
        for (final MapEntry(key: lang, value: json) in files.entries)
          lang: (json['names'] as Map<String, dynamic>).cast<String, String>(),
      };

  final Map<String, Map<String, String>> _names;

  static String path(String lang) => 'assets/data/saints/$lang.json';

  static Future<SaintsRepository> load(AssetBundle bundle) async => SaintsRepository.fromJson({
    for (final lang in contentLanguages)
      lang: jsonDecode(await bundle.loadString(path(lang))) as Map<String, dynamic>,
  });

  /// The name of celebration [id] in [lang], or else in English, or else the
  /// id itself rather than failing (r-13).
  String name(String id, String lang) => _names[lang]?[id] ?? _names['en']?[id] ?? id;

  /// Every id with a name in [lang].
  Iterable<String> ids(String lang) => _names[lang]?.keys ?? const [];
}
