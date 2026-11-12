import 'dart:math' as math;

import '../../../../game/domain/board_geometry.dart';

/// Pure layout math. Does not read or mutate match state.
final class PawnLayoutSolver {
  const PawnLayoutSolver._();

  static int clusterKey(NormalizedBoardPoint point) =>
      (point.x * 1000).round() * 10000 + (point.y * 1000).round();

  /// Artwork-space displacement for pawns sharing a logical cell.
  /// A single pawn stays centered. Multiple pawns use stable slots.
  static math.Point<double> stackOffset(int stackIndex, int occupantCount) {
    if (occupantCount < 1 || stackIndex < 0 || stackIndex >= occupantCount) {
      throw RangeError('Invalid stack index or occupant count');
    }
    if (occupantCount == 1) {
      return const math.Point<double>(0, 0);
    }
    const offsets = <math.Point<double>>[
      math.Point<double>(-0.48, -0.48),
      math.Point<double>(0.48, -0.48),
      math.Point<double>(-0.48, 0.48),
      math.Point<double>(0.48, 0.48),
    ];
    final slot = offsets[stackIndex % offsets.length];
    return math.Point<double>(slot.x * 18, slot.y * 18);
  }
}
