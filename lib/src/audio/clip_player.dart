import 'dart:async';

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
}

/// [ClipPlayer] backed by `just_audio` (ExoPlayer on Android, the HTML audio
/// element on the web). Both keep the pitch when the speed changes.
class JustAudioClipPlayer implements ClipPlayer {
  final AudioPlayer _player = AudioPlayer();

  /// Completed to cut short the sequence that is playing.
  Completer<void> _interrupt = Completer<void>()..complete();

  void _interruptCurrent() {
    if (!_interrupt.isCompleted) _interrupt.complete();
  }

  @override
  Future<void> play(List<String> assets, {required double speed}) async {
    _interruptCurrent();
    final interrupt = _interrupt = Completer<void>();
    await _player.setSpeed(speed);
    for (final asset in assets) {
      if (interrupt.isCompleted) return;
      await _player.setAsset(asset);
      if (interrupt.isCompleted) return;
      final done = _player.processingStateStream.firstWhere((s) => s == ProcessingState.completed);
      unawaited(_player.play());
      await Future.any([done, interrupt.future]);
    }
    if (!interrupt.isCompleted) interrupt.complete();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    _interruptCurrent();
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    _interruptCurrent();
    await _player.dispose();
  }
}
