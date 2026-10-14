import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/mysteries.dart';
import '../models/localized_text.dart';
import '../models/mystery.dart';
import '../models/prayer.dart';

/// Languages for which devotional content ships in `assets/data`.
const List<String> contentLanguages = ['en', 'es', 'fr'];

/// Read-only access to the prayers and mysteries bundled with the app.
///
/// Content is stored as one JSON file per language (see ADR-005) and merged
/// here into [LocalizedText] values.
class ContentRepository {
  ContentRepository._(this._prayers, this._setTitles, this._mysteries);

  final Map<String, Prayer> _prayers;
  final Map<MysterySet, LocalizedText> _setTitles;
  final Map<MysterySet, List<Mystery>> _mysteries;

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final prayerFiles = <String, Map<String, dynamic>>{};
    final mysteryFiles = <String, Map<String, dynamic>>{};
    for (final lang in contentLanguages) {
      prayerFiles[lang] = await _readJson(bundle, 'assets/data/prayers/$lang.json');
      mysteryFiles[lang] = await _readJson(bundle, 'assets/data/mysteries/$lang.json');
    }
    return ContentRepository.fromJson(prayers: prayerFiles, mysteries: mysteryFiles);
  }

  /// Builds a repository from decoded JSON keyed by language code.
  factory ContentRepository.fromJson({
    required Map<String, Map<String, dynamic>> prayers,
    required Map<String, Map<String, dynamic>> mysteries,
  }) {
    // Keep the order of the English file (or first file) for display.
    final order = <String>[];
    final titles = <String, Map<String, String>>{};
    final texts = <String, Map<String, String>>{};
    final languages = [
      if (prayers.containsKey('en')) 'en',
      ...prayers.keys.where((l) => l != 'en'),
    ];
    for (final lang in languages) {
      for (final raw in prayers[lang]!['prayers'] as List) {
        final p = raw as Map<String, dynamic>;
        final id = p['id'] as String;
        if (!order.contains(id)) order.add(id);
        (titles[id] ??= {})[lang] = p['title'] as String;
        (texts[id] ??= {})[lang] = p['text'] as String;
      }
    }
    final prayerMap = {
      for (final id in order)
        id: Prayer(id: id, title: LocalizedText(titles[id]!), text: LocalizedText(texts[id]!)),
    };

    final setTitles = <MysterySet, LocalizedText>{};
    final mysteryList = <MysterySet, List<Mystery>>{};
    for (final set in MysterySet.values) {
      final setTitle = <String, String>{};
      final perNumber = List.generate(
        mysteriesPerSet,
        (_) => <String, Map<String, String>>{'title': {}, 'scripture': {}, 'fruit': {}},
      );
      mysteries.forEach((lang, json) {
        final setJson = (json['sets'] as Map<String, dynamic>)[set.name] as Map<String, dynamic>?;
        if (setJson == null) return;
        setTitle[lang] = setJson['title'] as String;
        final items = setJson['mysteries'] as List;
        for (var i = 0; i < items.length && i < mysteriesPerSet; i++) {
          final m = items[i] as Map<String, dynamic>;
          for (final field in const ['title', 'scripture', 'fruit']) {
            perNumber[i][field]![lang] = m[field] as String;
          }
        }
      });
      setTitles[set] = LocalizedText(setTitle);
      mysteryList[set] = [
        for (var i = 0; i < mysteriesPerSet; i++)
          Mystery(
            set: set,
            number: i + 1,
            title: LocalizedText(perNumber[i]['title']!),
            scripture: LocalizedText(perNumber[i]['scripture']!),
            fruit: LocalizedText(perNumber[i]['fruit']!),
          ),
      ];
    }
    return ContentRepository._(prayerMap, setTitles, mysteryList);
  }

  static Future<Map<String, dynamic>> _readJson(AssetBundle bundle, String path) async =>
      jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>;

  /// All prayers, in display order.
  List<Prayer> get prayers => List.unmodifiable(_prayers.values);

  Prayer? prayer(String id) => _prayers[id];

  LocalizedText mysterySetTitle(MysterySet set) => _setTitles[set]!;

  List<Mystery> mysteriesOf(MysterySet set) => _mysteries[set]!;

  /// The mystery for [decade] (1-5) of [set].
  Mystery mystery(MysterySet set, int decade) => _mysteries[set]![decade - 1];
}
