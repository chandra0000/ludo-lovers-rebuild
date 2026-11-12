import '../../game/domain/player_color.dart';

/// Transient presentation state for a pawn movement animation.
/// Never owns or mutates the authoritative match game state.
class MatchMovementPresentation {
  PlayerColor? color;
  int? pawnIndex;
  int startProgress = 0;
  int endProgress = 0;
  String? feedback;

  bool get isMoving => pawnIndex != null;

  bool matches(PlayerColor player, int index) =>
      color == player && pawnIndex == index;

  void begin({
    required PlayerColor player,
    required int index,
    required int start,
    required int end,
    String? moveFeedback,
  }) {
    color = player;
    pawnIndex = index;
    startProgress = start;
    endProgress = end;
    feedback = moveFeedback;
  }

  /// Clears the active movement and returns feedback for the UI to display.
  String? complete() {
    final message = feedback;
    color = null;
    pawnIndex = null;
    feedback = null;
    return message;
  }

  void clear() {
    color = null;
    pawnIndex = null;
    feedback = null;
    startProgress = 0;
    endProgress = 0;
  }
}
