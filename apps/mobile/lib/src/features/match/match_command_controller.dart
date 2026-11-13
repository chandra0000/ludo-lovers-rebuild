import '../../game/application/match_session.dart';
import '../../game/domain/ludo_game.dart';

/// Owns command orchestration without duplicating the authoritative game state.
///
/// UI animations and persistence remain presentation concerns. Every accepted
/// state transition is produced exclusively by [MatchSession.execute].
class MatchCommandController {
  MatchCommandController(this._session);

  MatchSession _session;

  MatchSession get session => _session;
  LudoGame get game => _session.game;

  /// Builds a command for the currently active actor and state version.
  /// The MatchSession still validates and applies it on execute.
  RollDiceCommand buildRoll({
    required int value,
    required bool isAi,
    required int aiSeed,
  }) {
    final prefix = isAi ? 'ai-$aiSeed' : 'match';
    return RollDiceCommand(
      matchId: _session.matchId,
      actorId: _session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: '$prefix-${game.stateVersion}-roll',
      value: value,
    );
  }

  MovePawnCommand buildMove(int pawnIndex) {
    return MovePawnCommand(
      matchId: _session.matchId,
      actorId: _session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: 'match-${game.stateVersion}-move-$pawnIndex',
      pawnIndex: pawnIndex,
    );
  }

  PassTurnCommand buildPass() {
    return PassTurnCommand(
      matchId: _session.matchId,
      actorId: _session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: 'match-${game.stateVersion}-pass',
    );
  }

  MatchCommandResult execute(MatchCommand command) {
    final result = _session.execute(command);
    if (result.accepted) {
      _session = result.session;
    }
    return result;
  }

  /// Start a new match without retaining stale command identities or turns.
  void reset(MatchSession session) {
    _session = session;
  }
}
