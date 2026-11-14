import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Pure layout metrics for the approved 576×1024 board coordinate space.
///
/// The board remains a single uniform transform; interactive HUD elements can
/// consume [freeTop] and [freeBottom] without modifying pawn geometry.
@immutable
class MatchAdaptiveLayout {
  const MatchAdaptiveLayout._({
    required this.scale,
    required this.stageSize,
    required this.freeTop,
    required this.freeBottom,
    required this.compact,
  });

  final double scale;
  final Size stageSize;
  final double freeTop;
  final double freeBottom;
  final bool compact;

  static MatchAdaptiveLayout resolve({
    required Size available,
    required Size canvas,
  }) {
    assert(available.width > 0 && available.height > 0);
    assert(canvas.width > 0 && canvas.height > 0);
    final scale = math.min(
      available.width / canvas.width,
      available.height / canvas.height,
    );
    final stage = Size(canvas.width * scale, canvas.height * scale);
    final verticalGutter = math.max(0.0, (available.height - stage.height) / 2);
    return MatchAdaptiveLayout._(
      scale: scale,
      stageSize: stage,
      freeTop: verticalGutter,
      freeBottom: verticalGutter,
      compact: available.width < 360 || available.height < 700,
    );
  }
}
