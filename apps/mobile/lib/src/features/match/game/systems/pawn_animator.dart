import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../../game/domain/board_geometry.dart';
import '../../../../game/domain/player_color.dart';

/// Computes a visual hop from an already-accepted immutable match snapshot.
class PawnAnimator {
  const PawnAnimator._();

  static NormalizedBoardPoint position({
    required PlayerColor color,
    required int pawnIndex,
    required int progress,
    required bool isMoving,
    required int startProgress,
    required int endProgress,
    required double animationValue,
  }) {
    if (!isMoving) {
      return BoardGeometry.normalizedPosition(color, progress, pawnIndex);
    }
    final steps = endProgress - startProgress;
    if (steps <= 0) {
      return BoardGeometry.normalizedPosition(color, progress, pawnIndex);
    }
    final travelled = animationValue * steps;
    final stepIndex = math.min(travelled.floor(), steps - 1).toInt();
    final linearFraction = (travelled - stepIndex).clamp(0.0, 1.0).toDouble();
    final fraction = Curves.easeInOutCubic.transform(linearFraction);
    final fromProgress = startProgress + stepIndex;
    const hopHeight = 14.0;
    final hopArc = 4 * hopHeight * fraction * (1 - fraction);
    final point = BoardGeometry.interpolateRouteStep(
      color,
      fromProgress,
      pawnIndex,
      fraction,
    );
    return NormalizedBoardPoint(
      point.x,
      point.y - hopArc / BoardGeometry.canvasHeight,
    );
  }
}
