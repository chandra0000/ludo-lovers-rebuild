import '../../game/domain/ludo_game.dart';

/// Maps authoritative move rejections to display text without changing rules.
class MatchFxListener {
  const MatchFxListener._();

  static String invalidMoveMessage(MoveInvalidReason reason) {
    return switch (reason) {
      MoveInvalidReason.pawnInYardNeedsSix => 'ROLL A SIX TO ENTER',
      MoveInvalidReason.overshootsHome => 'EXACT ROLL NEEDED TO FINISH',
      MoveInvalidReason.pathBlockedByBlockade =>
        'PATH BLOCKED BY A PAWN BLOCKADE',
      MoveInvalidReason.landingOnProtectedStack => 'THAT STACK IS PROTECTED',
      MoveInvalidReason.noPendingRoll => 'ROLL THE DICE FIRST',
      MoveInvalidReason.invalidPawnIndex => 'INVALID PAWN SELECTION',
      MoveInvalidReason.invalidDice => 'DICE VALUE MUST BE 1 TO 6',
    };
  }
}
