import '../../game/application/match_session.dart';
import '../../game/domain/ludo_game.dart';
import '../../../features/game/domain/ludo_turn_engine.dart';

/// Owns command orchestration without duplicating the authoritative game state.
///
/// UI animations and persistence remain presentation concerns. Every accepted
/// state transition is produced exclusively by [MatchSession.execute].
class MatchCommandController {
  MatchCommandController(MatchSession session)
      : turns = LudoTurnEngine(session);

  final LudoTurnEngine turns;

  MatchSession get session => turns.session;
  LudoGame get game => session.game;

  /// Builds a command for the currently active actor and state version.
  /// The MatchSession still validates and applies it on execute.
  RollDiceCommand buildRoll({
    required int value,
    required bool isAi,
    required int aiSeed,
  }) {
    final prefix = isAi ? 'ai-$aiSeed' : 'match';
    return RollDiceCommand(
      matchId: session.matchId,
      actorId: session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: '$prefix-${game.stateVersion}-roll',
      value: value,
    );
  }

  MovePawnCommand buildMove(int pawnIndex) {
    return MovePawnCommand(
      matchId: session.matchId,
      actorId: session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: 'match-${game.stateVersion}-move-$pawnIndex',
      pawnIndex: pawnIndex,
    );
  }

  PassTurnCommand buildPass() {
    return PassTurnCommand(
      matchId: session.matchId,
      actorId: session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: 'match-${game.stateVersion}-pass',
    );
  }

  MatchCommandResult execute(MatchCommand command) {
    return turns.execute(command);
  }

  /// Start a new match without retaining stale command identities or turns.
  void reset(MatchSession session) {
    turns.reset(session);
  }

  void dispose() => turns.dispose();
}
