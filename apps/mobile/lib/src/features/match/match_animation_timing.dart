import 'dart:math' as math;

/// Presentation-only animation timing. MatchSession remains authoritative.
class MatchAnimationTiming {
  const MatchAnimationTiming();

  Duration pawnMovement({
    required int stepCount,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return Duration.zero;
    return Duration(milliseconds: math.max(180, stepCount * 125).toInt());
  }
}
