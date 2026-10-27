import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/mysteries.dart';
import '../models/localized_text.dart';
import '../models/mystery.dart';
import '../models/prayer.dart';
import '../models/prayer_note.dart';

/// Languages for which devotional content ships in `assets/data`.
const List<String> contentLanguages = ['en', 'es', 'fr'];

/// Read-only access to the prayers and mysteries bundled with the app.
///
/// Content is stored as one JSON file per language (see ADR-005) and merged
/// here into [LocalizedText] values.
class ContentRepository {
  ContentRepository._(this._prayers, this._setTitles, this._mysteries, this._ordinals, this._notes);

  final Map<String, Prayer> _prayers;
  final Map<MysterySet, LocalizedText> _setTitles;
  final Map<MysterySet, List<Mystery>> _mysteries;
  final List<LocalizedText> _ordinals;
  final Map<String, PrayerNote> _notes;

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final prayerFiles = <String, Map<String, dynamic>>{};
    final mysteryFiles = <String, Map<String, dynamic>>{};
    final noteFiles = <String, Map<String, dynamic>>{};
    for (final lang in contentLanguages) {
      prayerFiles[lang] = await _readJson(bundle, 'assets/data/prayers/$lang.json');
      mysteryFiles[lang] = await _readJson(bundle, 'assets/data/mysteries/$lang.json');
      noteFiles[lang] = await _readJson(bundle, notesPath(lang));
    }
    return ContentRepository.fromJson(
      prayers: prayerFiles,
      mysteries: mysteryFiles,
      notes: noteFiles,
    );
  }

  /// The background notes on the prayers in [lang].
  static String notesPath(String lang) => 'assets/data/prayer_notes/$lang.json';

  /// Builds a repository from decoded JSON keyed by language code.
  factory ContentRepository.fromJson({
    required Map<String, Map<String, dynamic>> prayers,
    required Map<String, Map<String, dynamic>> mysteries,
    Map<String, Map<String, dynamic>> notes = const {},
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
    final ordinals = [
      for (var i = 0; i < mysteriesPerSet; i++)
        LocalizedText({
          for (final MapEntry(key: lang, value: json) in mysteries.entries)
            if ((json['ordinals'] as List?)?.length case final n? when n > i)
              lang: (json['ordinals'] as List)[i] as String,
        }),
    ];
    final noteFields = <String, Map<String, Map<String, String>>>{};
    notes.forEach((lang, json) {
      (json['notes'] as Map<String, dynamic>).forEach((id, raw) {
        (raw as Map<String, dynamic>).forEach((field, text) {
          ((noteFields[id] ??= {})[field] ??= {})[lang] = text as String;
        });
      });
    });
    final noteMap = {
      for (final MapEntry(key: id, value: f) in noteFields.entries)
        if (f['origin'] != null && f['use'] != null)
          id: PrayerNote(
            origin: LocalizedText(f['origin']!),
            use: LocalizedText(f['use']!),
            scripture: f['scripture'] == null ? null : LocalizedText(f['scripture']!),
          ),
    };
    return ContentRepository._(prayerMap, setTitles, mysteryList, ordinals, noteMap);
  }

  static Future<Map<String, dynamic>> _readJson(AssetBundle bundle, String path) async =>
      jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>;

  /// All prayers, in display order.
  List<Prayer> get prayers => List.unmodifiable(_prayers.values);

  Prayer? prayer(String id) => _prayers[id];

  /// Background on the prayer [id], or null if it has none.
  PrayerNote? note(String id) => _notes[id];

  LocalizedText mysterySetTitle(MysterySet set) => _setTitles[set]!;

  List<Mystery> mysteriesOf(MysterySet set) => _mysteries[set]!;

  /// Spoken ordinal for [decade] (1-5), e.g. "First mystery".
  LocalizedText ordinal(int decade) => _ordinals[decade - 1];

  /// The mystery for [decade] (1-5) of [set].
  Mystery mystery(MysterySet set, int decade) => _mysteries[set]![decade - 1];
}
