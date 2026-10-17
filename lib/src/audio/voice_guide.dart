import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/rosary_session.dart';
import 'audio_catalog.dart';
import 'clip_player.dart';
import 'clips.dart';

/// Reads the Rosary aloud as the person moves through it (DESIGN §3.7).
///
/// Follows [session]: each new step stops the current clip and plays the
/// new one. With auto-advance on, it moves to the next step [pause] after a
/// clip ends, so the person can simply listen and pray along.
class VoiceGuide extends ChangeNotifier {
  VoiceGuide({
    required this.session,
    required this.catalog,
    required this.player,
    required this.language,
    bool enabled = false,
    this.speed = 1.0,
    this.autoAdvance = false,
    this.pause = const Duration(seconds: 2),
    this.withGuidance = true,
  }) : _enabled = enabled && catalog.hasLanguage(language) {
    session.addListener(_onStep);
    if (_enabled) _speak();
  }

  final RosarySession session;
  final AudioCatalog catalog;
  final ClipPlayer player;
  final String language;

  /// Playback speed, 0.75 to 1.25 (see [speeds]).
  double speed;
  bool autoAdvance;
  Duration pause;
  bool withGuidance;

  /// Speeds offered to the person: a little slower or faster than recorded.
  static const speeds = [0.75, 0.85, 1.0, 1.15, 1.25];

  bool _enabled;
  int _turn = 0;
  Timer? _advance;

  bool get available => catalog.hasLanguage(language);
  bool get enabled => _enabled;

  void toggle() => setEnabled(!_enabled);

  void setEnabled(bool value) {
    if (!available || value == _enabled) return;
    _enabled = value;
    notifyListeners();
    if (value) {
      _speak();
    } else {
      _silence();
    }
  }

  void setSpeed(double value) {
    speed = value;
    unawaited(player.setSpeed(value));
    notifyListeners();
  }

  void setAutoAdvance(bool value) {
    autoAdvance = value;
    notifyListeners();
  }

  void _onStep() {
    if (!_enabled) return;
    if (session.isFinished) {
      _silence();
    } else {
      _speak();
    }
  }

  void _silence() {
    _turn++;
    _advance?.cancel();
    unawaited(player.stop());
  }

  Future<void> _speak() async {
    final turn = ++_turn;
    _advance?.cancel();
    final assets = clipsForStep(
      session.current,
      session.mysterySet,
      withGuidance: withGuidance,
    ).map((id) => catalog.asset(language, id)).nonNulls.toList();
    await player.stop();
    if (turn != _turn) return;
    await player.play(assets, speed: speed);
    // Only the turn that is still current may auto-advance.
    if (turn != _turn || !_enabled || !autoAdvance || session.isFinished) return;
    _advance = Timer(pause, () {
      if (turn == _turn) session.next();
    });
  }

  @override
  void dispose() {
    session.removeListener(_onStep);
    _turn++;
    _advance?.cancel();
    unawaited(player.stop());
    super.dispose();
  }
}
