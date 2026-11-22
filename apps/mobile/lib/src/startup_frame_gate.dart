import 'package:flutter/widgets.dart';

/// Cold-bootstrap ownership, created before runApp, never during widget layout.
/// Readiness/error/disposal all release once, after render finalization. Changing
/// sendFramesToEngine during finalizeTree violates WidgetsBinding frame timing.
class StartupFrameGate {
  StartupFrameGate(this.binding) {
    binding.deferFirstFrame();
  }
  final WidgetsBinding binding;
  bool _releaseScheduled = false;

  void release() {
    if (_releaseScheduled) return;
    _releaseScheduled = true;
    binding.addPostFrameCallback((_) => binding.allowFirstFrame());
    binding.scheduleFrame();
  }
}
