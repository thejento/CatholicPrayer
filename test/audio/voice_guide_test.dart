import 'package:crc/src/audio/audio_catalog.dart';
import 'package:crc/src/audio/clips.dart';
import 'package:crc/src/audio/voice_guide.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/domain/rosary_session.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_clip_player.dart';

const catalog = AudioCatalog({
  'en': {
    'guide_signOfCrossStart': 'a/guide1.mp3',
    'prayer_sign_of_the_cross': 'a/sign.mp3',
    'guide_creed': 'a/guide2.mp3',
    'prayer_apostles_creed': 'a/creed.mp3',
  },
});

void main() {
  late RosarySession session;
  late FakeClipPlayer player;

  VoiceGuide guide({bool enabled = true, bool withGuidance = true, bool autoAdvance = false}) =>
      VoiceGuide(
        session: session,
        catalog: catalog,
        player: player,
        language: 'en',
        enabled: enabled,
        withGuidance: withGuidance,
        autoAdvance: autoAdvance,
        pause: const Duration(seconds: 2),
      );

  setUp(() {
    session = RosarySession(mysterySet: MysterySet.joyful);
    player = FakeClipPlayer();
  });

  test('plays the guidance then the prayer of the current step', () {
    fakeAsync((async) {
      guide();
      async.flushMicrotasks();
      expect(player.last, ['a/guide1.mp3', 'a/sign.mp3']);
    });
  });

  test('can skip the spoken guidance', () {
    fakeAsync((async) {
      guide(withGuidance: false);
      async.flushMicrotasks();
      expect(player.last, ['a/sign.mp3']);
    });
  });

  test('moving to another step stops the clip and plays the new one', () {
    fakeAsync((async) {
      guide();
      async.flushMicrotasks();
      session.next();
      async.flushMicrotasks();
      expect(player.stops, greaterThanOrEqualTo(2));
      expect(player.last, ['a/guide2.mp3', 'a/creed.mp3']);
    });
  });

  test('stays silent when disabled, and speaks when turned on', () {
    fakeAsync((async) {
      final g = guide(enabled: false);
      async.flushMicrotasks();
      expect(player.played, isEmpty);
      g.toggle();
      async.flushMicrotasks();
      expect(g.enabled, isTrue);
      expect(player.played, hasLength(1));
      g.toggle();
      async.flushMicrotasks();
      expect(player.isPlaying, isFalse);
    });
  });

  test('is unavailable without recordings for the language', () {
    final g = VoiceGuide(
      session: session,
      catalog: const AudioCatalog.empty(),
      player: player,
      language: 'en',
      enabled: true,
    );
    expect(g.available, isFalse);
    expect(g.enabled, isFalse);
    g.toggle();
    expect(g.enabled, isFalse);
  });

  test('auto-advance moves on after the pause', () {
    fakeAsync((async) {
      guide(autoAdvance: true);
      async.flushMicrotasks();
      player.finish();
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1900));
      expect(session.index, 0);
      async.elapse(const Duration(milliseconds: 200));
      expect(session.index, 1);
      async.flushMicrotasks();
      expect(player.last, ['a/guide2.mp3', 'a/creed.mp3']);
    });
  });

  test('auto-advance waits on a mystery announcement, then resumes', () {
    fakeAsync((async) {
      final announce = session.steps.indexWhere((s) => s.kind == StepKind.announceMystery);
      session = RosarySession(mysterySet: MysterySet.joyful, startIndex: announce);
      final voice = guide(autoAdvance: true);
      expect(voice.waitsHere, isTrue);
      async.flushMicrotasks();
      player.finish();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));
      expect(session.index, announce); // time to read the passage
      session.next(); // the Our Father
      expect(voice.waitsHere, isFalse);
      async.flushMicrotasks();
      player.finish();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      expect(session.index, announce + 2);
    });
  });

  test('reports how long the prayer takes to read, not the instruction', () {
    fakeAsync((async) {
      final voice = guide();
      async.flushMicrotasks();
      player.start('a/guide1.mp3', const Duration(seconds: 4));
      expect(voice.reading.value, isNull);
      player.start('a/sign.mp3', const Duration(seconds: 6));
      expect(voice.reading.value, const Duration(seconds: 6));

      session.next();
      expect(voice.reading.value, isNull); // a new step
      async.flushMicrotasks();
      voice.setSpeed(1.25);
      player.start('a/creed.mp3', const Duration(seconds: 25));
      expect(voice.reading.value, const Duration(seconds: 20));

      voice.toggle();
      expect(voice.reading.value, isNull); // voice off
    });
  });

  test('without auto-advance, finishing a clip waits for the person', () {
    fakeAsync((async) {
      guide();
      async.flushMicrotasks();
      player.finish();
      async.elapse(const Duration(seconds: 10));
      expect(session.index, 0);
    });
  });

  test('a manual move during the pause cancels the pending advance', () {
    fakeAsync((async) {
      guide(autoAdvance: true);
      async.flushMicrotasks();
      player.finish();
      async.flushMicrotasks();
      session.next(); // the person moves on during the pause
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      expect(session.index, 1);
    });
  });

  test('speed changes apply to the playing clip and the next ones', () {
    fakeAsync((async) {
      final g = guide();
      async.flushMicrotasks();
      g.setSpeed(1.25);
      session.next();
      async.flushMicrotasks();
      expect(player.speeds, [1.0, 1.25, 1.25]);
    });
  });

  test('finishing the Rosary silences the voice', () {
    fakeAsync((async) {
      session = RosarySession(mysterySet: MysterySet.joyful, startIndex: 79);
      guide();
      async.flushMicrotasks();
      session.next();
      async.flushMicrotasks();
      expect(session.isFinished, isTrue);
      expect(player.isPlaying, isFalse);
    });
  });

  test('disposing stops the voice', () {
    fakeAsync((async) {
      final g = guide();
      async.flushMicrotasks();
      g.dispose();
      expect(player.isPlaying, isFalse);
      session.next();
      async.flushMicrotasks();
      expect(player.played, hasLength(1));
    });
  });

  test('mystery announcements use the mystery clip', () {
    final step = session.steps.firstWhere((s) => s.prayerId == null);
    expect(clipsForStep(step, MysterySet.sorrowful, withGuidance: false), ['mystery_sorrowful_1']);
  });

  test('spoken prayers drop V./R. markers', () {
    expect(spokenPrayer('Hello.\n\nV. Pray for us.\nR. Amen.'), 'Hello. Pray for us. Amen.');
  });
}
