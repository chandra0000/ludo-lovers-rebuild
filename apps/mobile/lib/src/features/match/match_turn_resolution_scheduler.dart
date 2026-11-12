import 'dart:async';

/// Coordinates delayed turn presentation without owning match rules.
/// Cancelling invalidates callbacks from an earlier turn or match.
class MatchTurnResolutionScheduler {
  int _generation = 0;

  void cancel() {
    _generation++;
  }

  void schedule(Duration delay, void Function() onReady) {
    final generation = ++_generation;
    unawaited(
      Future<void>.delayed(delay, () {
        if (generation != _generation) return;
        onReady();
      }),
    );
  }
}
