import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/domain/rosary_sequence.dart';
import 'package:crc/src/domain/rosary_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RosarySession session;
  late int notifications;

  setUp(() {
    session = RosarySession(mysterySet: MysterySet.joyful);
    notifications = 0;
    session.addListener(() => notifications++);
  });

  test('starts on the first step', () {
    expect(session.index, 0);
    expect(session.isFirst, isTrue);
    expect(session.isFinished, isFalse);
    expect(session.progress, 0);
    expect(session.current.kind, StepKind.signOfTheCross);
  });

  test('previous on the first step does nothing', () {
    session.previous();
    expect(session.index, 0);
    expect(notifications, 0);
  });

  test('next and previous move one step and notify', () {
    session.next();
    expect(session.index, 1);
    expect(session.current.kind, StepKind.apostlesCreed);
    session.previous();
    expect(session.index, 0);
    expect(notifications, 2);
  });

  test('walking all steps finishes the Rosary', () {
    for (var i = 0; i < session.length; i++) {
      session.next();
    }
    expect(session.isFinished, isTrue);
    expect(session.progress, 1);
    expect(session.index, session.length - 1);

    session.next(); // ignored once finished
    expect(notifications, session.length);
  });

  test('previous from finished returns to the last step', () {
    for (var i = 0; i < session.length; i++) {
      session.next();
    }
    session.previous();
    expect(session.isFinished, isFalse);
    expect(session.isLast, isTrue);
  });

  test('restart goes back to the beginning', () {
    session
      ..next()
      ..next()
      ..restart();
    expect(session.index, 0);
    expect(session.isFinished, isFalse);
  });

  test('progress grows monotonically', () {
    var last = -1.0;
    while (!session.isFinished) {
      expect(session.progress, greaterThan(last));
      last = session.progress;
      session.next();
    }
  });

  test('rejects an empty sequence', () {
    expect(
      () => RosarySession(mysterySet: MysterySet.joyful, steps: const []),
      throwsArgumentError,
    );
  });

  test('can start on a saved step', () {
    final resumed = RosarySession(mysterySet: MysterySet.joyful, startIndex: 10);
    expect(resumed.index, 10);
  });

  test('clamps an out-of-range saved step', () {
    expect(RosarySession(mysterySet: MysterySet.joyful, startIndex: 999).isLast, isTrue);
    expect(RosarySession(mysterySet: MysterySet.joyful, startIndex: -4).isFirst, isTrue);
  });
}
