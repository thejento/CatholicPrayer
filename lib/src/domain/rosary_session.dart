import 'package:flutter/foundation.dart';

import 'mysteries.dart';
import 'rosary_sequence.dart';

/// Tracks progress through one Rosary, one step at a time.
class RosarySession extends ChangeNotifier {
  RosarySession({
    required this.mysterySet,
    this.mode = RosaryMode.guided,
    List<RosaryStep>? steps,
    int startIndex = 0,
  }) : steps = steps ?? buildSequence(mode) {
    if (this.steps.isEmpty) {
      throw ArgumentError.value(steps, 'steps', 'must not be empty');
    }
    // A saved index from an older sequence may be out of range: clamp it.
    _index = startIndex.clamp(0, this.steps.length - 1);
  }

  final MysterySet mysterySet;
  final RosaryMode mode;
  final List<RosaryStep> steps;

  int _index = 0;
  bool _finished = false;

  int get index => _index;
  RosaryStep get current => steps[_index];
  int get length => steps.length;
  bool get isFirst => _index == 0;
  bool get isLast => _index == steps.length - 1;

  /// True once the person has moved past the last step.
  bool get isFinished => _finished;

  /// Fraction of steps completed, from 0.0 to 1.0.
  double get progress => _finished ? 1 : _index / steps.length;

  /// Moves to the next step, or finishes the Rosary from the last step.
  void next() {
    if (_finished) return;
    if (isLast) {
      _finished = true;
    } else {
      _index++;
    }
    notifyListeners();
  }

  /// Moves back one step. From the finished state, returns to the last step.
  void previous() {
    if (_finished) {
      _finished = false;
    } else if (!isFirst) {
      _index--;
    } else {
      return;
    }
    notifyListeners();
  }

  void restart() {
    _index = 0;
    _finished = false;
    notifyListeners();
  }
}
