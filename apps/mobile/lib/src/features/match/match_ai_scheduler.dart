import 'dart:async';

/// Owns the delayed AI turn callback without owning any game rules or state.
/// A generation token prevents callbacks from an old match after restart.
class MatchAiScheduler {
  bool _scheduled = false;
  Timer? _timer;
  int _generation = 0;

  bool get isScheduled => _scheduled;

  void schedule(void Function() onReady) {
    if (_scheduled) return;
    _scheduled = true;
    final generation = _generation;
    _timer = Timer(const Duration(milliseconds: 450), () {
      if (generation != _generation) return;
      _timer = null;
      _scheduled = false;
      onReady();
    });
  }

  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _scheduled = false;
  }
}
