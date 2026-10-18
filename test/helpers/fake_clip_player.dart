import 'dart:async';

import 'package:crc/src/audio/clip_player.dart';

/// Records what would be played; a test ends the current sequence with
/// [finish], as if the last clip had played to the end.
class FakeClipPlayer implements ClipPlayer {
  final List<List<String>> played = [];
  final List<double> speeds = [];
  int stops = 0;
  bool disposed = false;
  Completer<void>? _current;

  bool get isPlaying => _current != null && !_current!.isCompleted;
  List<String> get last => played.last;

  @override
  Future<void> play(List<String> assets, {required double speed}) {
    played.add(assets);
    speeds.add(speed);
    _current = Completer<void>();
    return _current!.future;
  }

  void finish() => _current?.complete();

  final _started = StreamController<StartedClip>.broadcast(sync: true);

  @override
  Stream<StartedClip> get started => _started.stream;

  /// Reports [asset] as starting, [duration] long at 1.0×.
  void start(String asset, Duration duration) => _started.add(StartedClip(asset, duration));

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> stop() async {
    stops++;
    if (isPlaying) _current!.complete();
  }

  @override
  Future<void> dispose() async => disposed = true;
}
