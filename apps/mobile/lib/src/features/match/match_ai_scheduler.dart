import 'dart:async';

/// Owns the delayed AI turn callback without owning any game rules or state.
/// A generation token prevents callbacks from an old match after restart.
class MatchAiScheduler {
  bool _scheduled = false;
  int _generation = 0;

  bool get isScheduled => _scheduled;

  void schedule(void Function() onReady) {
    if (_scheduled) return;
    _scheduled = true;
    final generation = _generation;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (generation != _generation) return;
        _scheduled = false;
        onReady();
      }),
    );
  }

  void cancel() {
    _generation++;
    _scheduled = false;
  }
}
