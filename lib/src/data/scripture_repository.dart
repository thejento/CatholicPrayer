import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/mysteries.dart';
import 'content_repository.dart';

@immutable
class Verse {
  const Verse(this.number, this.text);

  final int number;
  final String text;
}

/// The Bible passage of one mystery in one language (DESIGN §3.9).
@immutable
class Passage {
  const Passage({required this.chapter, required this.verses, required this.source});

  final int chapter;
  final List<Verse> verses;

  /// Translation and licence, shown under the passage.
  final String source;
}

/// The Bible passage of each mystery, bundled in `assets/data/scripture`
/// (built by `tool/scripture/build.py`, ADR-024).
class ScriptureRepository {
  ScriptureRepository._(this._passages);

  /// `{lang: {"joyful_1": Passage}}`.
  final Map<String, Map<String, Passage>> _passages;

  static String path(String lang) => 'assets/data/scripture/$lang.json';

  static Future<ScriptureRepository> load(AssetBundle bundle) async =>
      ScriptureRepository.fromJson({
        for (final lang in contentLanguages)
          lang: jsonDecode(await bundle.loadString(path(lang))) as Map<String, dynamic>,
      });

  factory ScriptureRepository.fromJson(Map<String, Map<String, dynamic>> files) {
    return ScriptureRepository._({
      for (final MapEntry(key: lang, value: json) in files.entries)
        lang: {
          for (final MapEntry(:key, :value) in (json['passages'] as Map<String, dynamic>).entries)
            key: Passage(
              chapter: (value as Map<String, dynamic>)['chapter'] as int,
              verses: [
                for (final v in value['verses'] as List)
                  Verse((v as Map<String, dynamic>)['v'] as int, v['t'] as String),
              ],
              source: '${json['source']} · ${json['license']}',
            ),
        },
    });
  }

  /// The passage of [decade] (1-5) of [set], in [lang] or else English.
  Passage? passage(MysterySet set, int decade, String lang) {
    final key = '${set.name}_$decade';
    return _passages[lang]?[key] ?? _passages['en']?[key];
  }
}
