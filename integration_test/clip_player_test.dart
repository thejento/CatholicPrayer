import 'package:crc/src/audio/audio_catalog.dart';
import 'package:crc/src/audio/clip_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs on a device or emulator (`flutter test integration_test -d <device>`)
/// or in Chrome (`flutter drive --driver=test_driver/integration_test.dart
/// --target=integration_test/clip_player_test.dart -d web-server`).
/// Plays a Rosary step's instruction then prayer through the real platform
/// player and checks that both clips play, in order (regression for the
/// voice repeating the instruction instead of reading the prayer).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('instruction then prayer both play, in order', (tester) async {
    final catalog = await AudioCatalog.load(rootBundle);
    const ids = ['guide_signOfCrossStart', 'prayer_sign_of_the_cross'];
    final assets = [for (final id in ids) catalog.asset('en', id)!];
    final player = JustAudioClipPlayer();
    final started = <String>[];
    final lengths = <Duration?>[];
    final sub = player.started.listen((c) {
      started.add(c.asset.split('/').last);
      lengths.add(c.duration);
    });

    final watch = Stopwatch()..start();
    await tester.runAsync(() => player.play(assets, speed: 1.0));
    watch.stop();
    await sub.cancel();
    await tester.runAsync(player.dispose);

    expect(started, ['guide_signOfCrossStart.mp3', 'prayer_sign_of_the_cross.mp3']);
    // Instruction (3.0 s) and prayer (4.6 s) both play to the end; the old
    // player replayed the instruction and finished after about 6 s in Chrome.
    expect(watch.elapsedMilliseconds, greaterThan(7000));
    // Auto-scroll paces itself on the prayer's length, so the platform must report it.
    expect(lengths.last?.inMilliseconds, inInclusiveRange(4000, 5500));
  });

  testWidgets('a new step interrupts the current one', (tester) async {
    final catalog = await AudioCatalog.load(rootBundle);
    final player = JustAudioClipPlayer();
    final creed = [catalog.asset('en', 'prayer_apostles_creed')!];
    final stoppedAfter = await tester.runAsync(() async {
      final first = player.play(creed, speed: 1.0);
      await Future<void>.delayed(const Duration(seconds: 2));
      final watch = Stopwatch()..start();
      await player.stop();
      await first;
      await player.dispose();
      return watch.elapsedMilliseconds;
    });
    expect(
      stoppedAfter,
      lessThan(2000),
      reason: 'stop ends play() promptly, not after the 38 s Creed',
    );
  });
}
