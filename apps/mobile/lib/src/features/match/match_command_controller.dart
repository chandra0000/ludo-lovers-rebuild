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
