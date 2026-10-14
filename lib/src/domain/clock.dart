/// Injectable source of the current time, so date logic is testable.
class Clock {
  const Clock([this._now = DateTime.now]);

  /// A clock frozen at [time].
  Clock.fixed(DateTime time) : _now = (() => time);

  final DateTime Function() _now;

  DateTime now() => _now();
}
