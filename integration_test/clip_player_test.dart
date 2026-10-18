import 'package:crc/src/audio/audio_catalog.dart';
import 'package:crc/src/audio/clip_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs on a device or emulator: `flutter test integration_test`.
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
    final indices = <int?>[];
    final sub = player.currentIndexStream.listen(indices.add);

    final watch = Stopwatch()..start();
    await tester.runAsync(() => player.play(assets, speed: 1.0));
    watch.stop();
    await sub.cancel();
    await tester.runAsync(player.dispose);

    // ignore: avoid_print
    print('indices=$indices elapsed=${watch.elapsedMilliseconds}ms');
    expect(indices.where((i) => i != null).toSet(), {0, 1}, reason: 'both clips played');
    expect(indices.lastWhere((i) => i != null), 1, reason: 'ended on the prayer');
    // Both clips together last a few seconds; a cut-short playlist would be faster.
    expect(watch.elapsedMilliseconds, greaterThan(4000));
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
