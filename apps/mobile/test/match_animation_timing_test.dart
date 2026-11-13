import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_animation_timing.dart';

void main() {
  const timing = MatchAnimationTiming();

  test('pawn movement preserves the 180ms minimum', () {
    expect(
      timing.pawnMovement(stepCount: 1, reduceMotion: false),
      const Duration(milliseconds: 180),
    );
  });

  test('pawn movement scales with steps', () {
    expect(
      timing.pawnMovement(stepCount: 6, reduceMotion: false),
      const Duration(milliseconds: 750),
    );
  });

  test('reduced motion skips movement animation', () {
    expect(
      timing.pawnMovement(stepCount: 6, reduceMotion: true),
      Duration.zero,
    );
  });
}
