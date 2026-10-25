import 'package:flutter/foundation.dart';

import '../data/preferences_store.dart';
import '../domain/mysteries.dart';
import '../domain/rosary_sequence.dart';

/// Where an unfinished Rosary was left off.
@immutable
class SavedSession {
  const SavedSession({
    required this.mysterySet,
    required this.index,
    this.mode = RosaryMode.guided,
  });

  final MysterySet mysterySet;
  final RosaryMode mode;

  /// Index of the step to resume on.
  final int index;

  /// `joyful:12` (guided, as saved by earlier versions) or `joyful:3:mysteriesOnly`.
  String encode() => mode == RosaryMode.guided
      ? '${mysterySet.name}:$index'
      : '${mysterySet.name}:$index:${mode.name}';

  /// Parses [encode]'s output; returns `null` for anything unexpected.
  static SavedSession? decode(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length < 2 || parts.length > 3) return null;
    final set = MysterySet.values.where((s) => s.name == parts[0]);
    final index = int.tryParse(parts[1]);
    final mode = parts.length == 2
        ? RosaryMode.guided
        : RosaryMode.values.where((m) => m.name == parts[2]).firstOrNull;
    if (set.isEmpty || index == null || index < 0 || mode == null) return null;
    return SavedSession(mysterySet: set.first, index: index, mode: mode);
  }

  @override
  bool operator ==(Object other) =>
      other is SavedSession &&
      other.mysterySet == mysterySet &&
      other.index == index &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(mysterySet, index, mode);
}

/// Persists the unfinished Rosary so it can be resumed after leaving the app
/// (backlog F-06). Starting from the first step or finishing clears it.
class SavedSessionController extends ChangeNotifier {
  SavedSessionController(this._store);

  static const prefsKey = 'saved_session';

  final PreferencesStore _store;
  SavedSession? _saved;

  SavedSession? get saved => _saved;

  Future<void> load() async {
    _saved = SavedSession.decode(await _store.getString(prefsKey));
    notifyListeners();
  }

  Future<void> save(SavedSession session) async {
    if (session.index == 0) return clear();
    if (session == _saved) return;
    _saved = session;
    notifyListeners();
    await _store.setString(prefsKey, session.encode());
  }

  Future<void> clear() async {
    if (_saved == null) return;
    _saved = null;
    notifyListeners();
    await _store.remove(prefsKey);
  }
}
