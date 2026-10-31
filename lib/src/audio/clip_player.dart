import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays bundled audio clips one after another. Abstracted so widget tests
/// can use a fake instead of the platform player.
abstract interface class ClipPlayer {
  /// Plays [assets] in order at [speed] (1.0 = recorded pace). Completes
  /// when the last clip ends, or early when [stop] is called.
  Future<void> play(List<String> assets, {required double speed});

  /// Changes the speed of the clip that is playing, if any.
  Future<void> setSpeed(double speed);

  Future<void> stop();

  Future<void> dispose();

  /// Each clip as it starts, with its recorded length.
  Stream<StartedClip> get started;
}

/// A clip that has just started; [duration] is at 1.0× (null if unknown).
@immutable
class StartedClip {
  const StartedClip(this.asset, this.duration);

  final String asset;
  final Duration? duration;
}

/// [ClipPlayer] backed by `just_audio` (ExoPlayer on Android, the HTML audio
/// element on the web). Both keep the pitch when the speed changes.
///
/// Each clip gets a fresh platform player, disposed when it ends. Reusing one
/// player for the step's second clip (the prayer after its instruction) failed
/// in the browser: it replayed the instruction instead (F-08 bug, see
/// integration_test/clip_player_test.dart).
class JustAudioClipPlayer implements ClipPlayer {
  AudioPlayer? _current;
  double _speed = 1.0;
  final _started = StreamController<StartedClip>.broadcast();

  @override
  Stream<StartedClip> get started => _started.stream;

  /// Completed to cut short the sequence that is playing.
  Completer<void> _interrupt = Completer<void>()..complete();

  void _interruptCurrent() {
    if (!_interrupt.isCompleted) _interrupt.complete();
  }

  @override
  Future<void> play(List<String> assets, {required double speed}) async {
    _interruptCurrent();
    final interrupt = _interrupt = Completer<void>();
    _speed = speed;
    for (final asset in assets) {
      if (interrupt.isCompleted) return;
      final player = _current = AudioPlayer();
      try {
        await player.setSpeed(_speed);
        final duration = await player.setAsset(asset);
        if (interrupt.isCompleted) return;
        _started.add(StartedClip(asset, duration));
        // play() completes when the clip ends, or when it is stopped.
        await Future.any([player.play(), interrupt.future]);
      } on PlayerInterruptedException {
        // Stopped while loading: the next step's clips are on their way.
        return;
      } finally {
        if (identical(_current, player)) _current = null;
        await player.dispose();
      }
    }
    if (!interrupt.isCompleted) interrupt.complete();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _current?.setSpeed(speed);
  }

  @override
  Future<void> stop() async {
    _interruptCurrent();
    await _current?.stop();
  }

  @override
  Future<void> dispose() async {
    _interruptCurrent();
    await _current?.stop();
    await _started.close();
  }
}
