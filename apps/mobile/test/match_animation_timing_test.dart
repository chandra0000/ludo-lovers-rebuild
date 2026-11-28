import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_animation_timing.dart';

void main() {
  const timing = MatchAnimationTiming();

  test('pawn movement uses a 95ms per-tile hop', () {
    expect(
      timing.pawnMovement(stepCount: 1, reduceMotion: false),
      const Duration(milliseconds: 95),
    );
  });

  test('pawn movement scales with steps', () {
    expect(
      timing.pawnMovement(stepCount: 6, reduceMotion: false),
      const Duration(milliseconds: 570),
    );
  });

  test('reduced motion skips movement animation', () {
    expect(
      timing.pawnMovement(stepCount: 6, reduceMotion: true),
      Duration.zero,
    );
  });
}
