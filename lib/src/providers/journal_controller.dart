import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/preferences_store.dart';
import '../domain/mysteries.dart';
import '../domain/rosary_sequence.dart';

/// One Rosary prayed to the end (F-13).
@immutable
class JournalEntry {
  const JournalEntry({
    required this.prayedAt,
    required this.mysterySet,
    this.mode = RosaryMode.guided,
    this.intention = '',
  });

  final DateTime prayedAt;
  final MysterySet mysterySet;
  final RosaryMode mode;

  /// What the Rosary was offered for, if the person wrote it down.
  final String intention;

  JournalEntry withIntention(String value) =>
      JournalEntry(prayedAt: prayedAt, mysterySet: mysterySet, mode: mode, intention: value);

  Map<String, Object> toJson() => {
    'at': prayedAt.toIso8601String(),
    'set': mysterySet.name,
    if (mode != RosaryMode.guided) 'mode': mode.name,
    if (intention.isNotEmpty) 'intention': intention,
  };

  /// Parses [toJson]'s output; returns `null` for anything unexpected.
  static JournalEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse(json['at'] as String? ?? '');
    final set = MysterySet.values.where((s) => s.name == json['set']).firstOrNull;
    final mode = json['mode'] == null
        ? RosaryMode.guided
        : RosaryMode.values.where((m) => m.name == json['mode']).firstOrNull;
    final intention = json['intention'] ?? '';
    if (at == null || set == null || mode == null || intention is! String) return null;
    return JournalEntry(prayedAt: at, mysterySet: set, mode: mode, intention: intention);
  }

  @override
  bool operator ==(Object other) =>
      other is JournalEntry &&
      other.prayedAt == prayedAt &&
      other.mysterySet == mysterySet &&
      other.mode == mode &&
      other.intention == intention;

  @override
  int get hashCode => Object.hash(prayedAt, mysterySet, mode, intention);
}

/// A private list of the Rosaries prayed, kept only on this device: no
/// account, no network, no cloud backup (DESIGN §3.20, ADR-034). No streaks.
class JournalController extends ChangeNotifier {
  JournalController(this._store);

  static const entriesKey = 'journal_entries';
  static const enabledKey = 'journal_enabled';

  /// Longest intention kept, in characters.
  static const maxIntention = 200;

  final PreferencesStore _store;
  bool _enabled = true;
  List<JournalEntry> _entries = const [];

  /// Whether finished Rosaries are added to the journal.
  bool get enabled => _enabled;

  /// Newest first.
  List<JournalEntry> get entries => _entries;

  /// Rosaries prayed in the month of [date].
  int countInMonth(DateTime date) =>
      _entries.where((e) => e.prayedAt.year == date.year && e.prayedAt.month == date.month).length;

  Future<void> load() async {
    _enabled = await _store.getBool(enabledKey) ?? true;
    _entries = _decode(await _store.getString(entriesKey));
    notifyListeners();
  }

  static List<JournalEntry> _decode(String? value) {
    if (value == null) return const [];
    try {
      final list = jsonDecode(value);
      if (list is! List) return const [];
      return List.unmodifiable(list.map(JournalEntry.fromJson).nonNulls);
    } on FormatException {
      return const [];
    }
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    await _store.setBool(enabledKey, value);
  }

  /// Adds [entry] when the journal is on; returns it, or `null` when off.
  Future<JournalEntry?> record(JournalEntry entry) async {
    if (!_enabled) return null;
    await _save([entry, ..._entries]);
    return entry;
  }

  /// Replaces [entry]'s intention; returns the updated entry.
  Future<JournalEntry> setIntention(JournalEntry entry, String intention) async {
    final trimmed = intention.trim();
    final updated = entry.withIntention(
      trimmed.length > maxIntention ? trimmed.substring(0, maxIntention) : trimmed,
    );
    final i = _entries.indexOf(entry);
    if (i < 0) return entry;
    await _save([..._entries]..[i] = updated);
    return updated;
  }

  Future<void> remove(JournalEntry entry) => _save([..._entries]..remove(entry));

  Future<void> clear() async {
    if (_entries.isEmpty) return;
    _entries = const [];
    notifyListeners();
    await _store.remove(entriesKey);
  }

  Future<void> _save(List<JournalEntry> entries) async {
    _entries = List.unmodifiable(entries);
    notifyListeners();
    await _store.setString(entriesKey, jsonEncode([for (final e in _entries) e.toJson()]));
  }
}
