import 'dart:async';

/// Coordinates delayed turn presentation without owning match rules.
/// Cancelling invalidates callbacks from an earlier turn or match.
class MatchTurnResolutionScheduler {
  int _generation = 0;
  Timer? _timer;

  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  void schedule(Duration delay, void Function() onReady) {
    cancel();
    final generation = _generation;
    _timer = Timer(delay, () {
      _timer = null;
      if (generation != _generation) return;
      onReady();
    });
  }
}
