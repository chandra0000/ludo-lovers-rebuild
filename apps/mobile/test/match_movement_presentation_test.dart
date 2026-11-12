import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_movement_presentation.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('movement state starts empty, tracks one pawn and clears', () {
    final movement = MatchMovementPresentation();
    expect(movement.isMoving, isFalse);
    movement.begin(
      player: PlayerColor.orange,
      index: 2,
      start: 4,
      end: 9,
      moveFeedback: 'Captured',
    );
    expect(movement.isMoving, isTrue);
    expect(movement.matches(PlayerColor.orange, 2), isTrue);
    expect(movement.matches(PlayerColor.blue, 2), isFalse);
    expect(movement.startProgress, 4);
    expect(movement.endProgress, 9);
    expect(movement.feedback, 'Captured');
    movement.clear();
    expect(movement.isMoving, isFalse);
    expect(movement.feedback, isNull);
    expect(movement.startProgress, 0);
    expect(movement.endProgress, 0);
  });
}
