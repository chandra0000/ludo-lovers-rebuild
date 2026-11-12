import '../../game/application/match_session.dart';
import '../../game/domain/player_color.dart';

/// Constructs versioned commands; MatchSession remains the only authority.
class MatchController {
  const MatchController._();

  static RollDiceCommand roll({
    required MatchSession session,
    required PlayerColor player,
    required String commandId,
    required int value,
  }) {
    return RollDiceCommand(
      matchId: session.matchId,
      actorId: session.actorFor(player),
      expectedStateVersion: session.game.stateVersion,
      commandId: commandId,
      value: value,
    );
  }

  static MovePawnCommand move({
    required MatchSession session,
    required PlayerColor player,
    required String commandId,
    required int pawnIndex,
  }) {
    return MovePawnCommand(
      matchId: session.matchId,
      actorId: session.actorFor(player),
      expectedStateVersion: session.game.stateVersion,
      commandId: commandId,
      pawnIndex: pawnIndex,
    );
  }

  static PassTurnCommand pass({
    required MatchSession session,
    required PlayerColor player,
    required String commandId,
  }) {
    return PassTurnCommand(
      matchId: session.matchId,
      actorId: session.actorFor(player),
      expectedStateVersion: session.game.stateVersion,
      commandId: commandId,
    );
  }
}
