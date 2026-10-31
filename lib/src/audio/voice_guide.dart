import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/rosary_sequence.dart';
import '../domain/rosary_session.dart';
import 'audio_catalog.dart';
import 'clip_player.dart';
import 'clips.dart';

/// Reads the Rosary aloud as the person moves through it (DESIGN §3.7).
///
/// Follows [session]: each new step stops the current clip and plays the
/// new one. With auto-advance on, it moves to the next step [pause] after a
/// clip ends, so the person can simply listen and pray along. It waits on
/// mystery announcements, where the Bible passage is read silently.
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
    this.onError,
  }) : _enabled = enabled && catalog.hasLanguage(language) {
    session.addListener(_onStep);
    _clips = player.started.listen(_onClipStarted);
    if (_enabled) unawaited(_speak());
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

  /// Called when a clip can't be played (r-10): the voice has turned itself
  /// off, so auto-advance doesn't wait for a clip that will never end.
  final VoidCallback? onError;

  /// Speeds offered to the person: a little slower or faster than recorded.
  static const speeds = [0.75, 0.85, 1.0, 1.15, 1.25];

  bool _enabled;
  int _turn = 0;
  Timer? _advance;
  late final StreamSubscription<StartedClip> _clips;

  /// The step's own clips (prayer or announcement), not its instruction.
  Set<String> _textAssets = {};

  /// How long the voice will take to read the step's text, set when that
  /// clip starts (at the current speed) and cleared when it stops. The step
  /// panel scrolls along with it (DESIGN §3.7).
  final reading = ValueNotifier<Duration?>(null);

  bool get available => catalog.hasLanguage(language);

  /// Auto-advance waits on mystery announcements: the passage is not read
  /// aloud yet, and its clip is too short to read it (F-18 can lift this).
  bool get waitsHere => _enabled && advances && session.current.kind == StepKind.announceMystery;

  /// Mysteries only: the person prays each decade alone, so the voice reads
  /// the announcement only and never moves on by itself (DESIGN §3.15).
  bool get _guided => session.mode == RosaryMode.guided;

  /// Whether auto-advance applies here: it is on, and the Rosary is guided.
  bool get advances => autoAdvance && _guided;
  bool get enabled => _enabled;

  void toggle() => setEnabled(!_enabled);

  void setEnabled(bool value) {
    if (!available || value == _enabled) return;
    _enabled = value;
    notifyListeners();
    if (value) {
      unawaited(_speak());
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
      unawaited(_speak());
    }
  }

  void _onClipStarted(StartedClip clip) {
    final length = clip.duration;
    if (!_enabled || length == null || !_textAssets.contains(clip.asset)) return;
    reading.value = Duration(microseconds: (length.inMicroseconds / speed).round());
  }

  void _silence() {
    reading.value = null;
    _turn++;
    _advance?.cancel();
    unawaited(player.stop());
  }

  Future<void> _speak() async {
    final turn = ++_turn;
    _advance?.cancel();
    reading.value = null;
    final ids = clipsForStep(
      session.current,
      session.mysterySet,
      withGuidance: withGuidance && _guided,
    );
    final assets = ids.map((id) => catalog.asset(language, id)).nonNulls.toList();
    _textAssets = {
      for (final id in ids)
        if (!isGuidanceClip(id)) ?catalog.asset(language, id),
    };
    try {
      await player.stop();
      if (turn != _turn) return;
      await player.play(assets, speed: speed);
    } catch (error) {
      // A newer step already took over: its own clips are playing.
      if (turn != _turn) return;
      debugPrint('Voice: could not play $assets: $error');
      _enabled = false;
      _silence();
      notifyListeners();
      onError?.call();
      return;
    }
    // Only the turn that is still current may auto-advance.
    if (turn != _turn || !_enabled || !advances || session.isFinished || waitsHere) return;
    _advance = Timer(pause, () {
      if (turn == _turn) session.next();
    });
  }

  @override
  void dispose() {
    session.removeListener(_onStep);
    unawaited(_clips.cancel());
    reading.dispose();
    _turn++;
    _advance?.cancel();
    unawaited(player.stop());
    super.dispose();
  }
}
