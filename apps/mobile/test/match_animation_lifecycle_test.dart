import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_animation_lifecycle.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('dice presentation tracks rolls and restores pending AI dice', () {
    final animations = MatchAnimationLifecycle(
      vsync: TestVSync(),
      onMovementTick: () {},
      onMovementStatus: (_) {},
    );
    addTearDown(animations.dispose);

    animations.presentAcceptedRoll(hasDiceResult: true);
    expect(animations.isDiceAnimating, isTrue);
    expect(animations.diceRollId, 1);

    animations.completeDiceRoll();
    expect(animations.isDiceAnimating, isFalse);

    animations.presentAcceptedRoll(hasDiceResult: false);
    expect(animations.diceRollId, 1);
    expect(animations.isDiceAnimating, isFalse);

    animations.restorePendingDiceRoll();
    expect(animations.isDiceAnimating, isTrue);
    expect(animations.diceRollId, 1);

    animations.resetForNewMatch();
    expect(animations.isDiceAnimating, isFalse);
    expect(animations.diceRollId, 0);
  });

  test('movement completion clears the transient pawn and feedback', () {
    final animations = MatchAnimationLifecycle(
      vsync: TestVSync(),
      onMovementTick: () {},
      onMovementStatus: (_) {},
    );
    addTearDown(animations.dispose);

    animations.configurePawnMovement(
      color: PlayerColor.orange,
      pawnIndex: 2,
      startProgress: -1,
      endProgress: 0,
      stepCount: 1,
      reduceMotion: false,
      feedback: 'PAWN HOME!',
    );

    expect(animations.pawn.isMoving, isTrue);
    expect(animations.pawn.matches(PlayerColor.orange, 2), isTrue);
    expect(animations.movement.duration, const Duration(milliseconds: 180));
    expect(animations.completePawnMovement(), 'PAWN HOME!');
    expect(animations.pawn.isMoving, isFalse);
    expect(animations.completePawnMovement(), isNull);
  });

  testWidgets('restart cancels in-flight animation without completion', (
    tester,
  ) async {
    var completions = 0;
    final animations = MatchAnimationLifecycle(
      vsync: TestVSync(),
      onMovementTick: () {},
      onMovementStatus: (status) {
        if (status == AnimationStatus.completed) completions++;
      },
    );
    addTearDown(animations.dispose);

    animations.presentAcceptedRoll(hasDiceResult: true);
    animations.configurePawnMovement(
      color: PlayerColor.blue,
      pawnIndex: 1,
      startProgress: 4,
      endProgress: 10,
      stepCount: 6,
      reduceMotion: false,
    );
    animations.startPawnMovement();
    await tester.pump(const Duration(milliseconds: 100));

    expect(animations.movement.isAnimating, isTrue);
    animations.resetForNewMatch();
    expect(animations.movement.isAnimating, isFalse);
    expect(animations.pawn.isMoving, isFalse);
    expect(animations.isDiceAnimating, isFalse);
    expect(animations.diceRollId, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(completions, 0);
  });
}
