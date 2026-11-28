import 'package:riverpod/riverpod.dart';

import '../../../src/game/application/match_session.dart';
import '../../../src/game/domain/ludo_game.dart';
import '../../../src/game/domain/player_color.dart';

enum LudoTurnPhase {
  awaitingRoll,
  rolling,
  evaluatingMoves,
  noMovesPass,
  awaitingBoardTap,
  animatingPawn,
  resolveTileEvent,
  checkVictory,
  nextTurn,
  completed,
}

/// Immutable presentation state over the sole authoritative MatchSession.
class LudoTurnState {
  const LudoTurnState(this.session, this.phase, this.presentedPlayer);
  final MatchSession session;
  final LudoTurnPhase phase;
  final PlayerColor presentedPlayer;
  bool get isInputLocked =>
      phase != LudoTurnPhase.awaitingRoll &&
      phase != LudoTurnPhase.awaitingBoardTap;
}

/// Riverpod-compatible coordinator; all rule decisions stay in MatchSession.
/// Timers/tickers live in the existing lifecycle-safe presentation controllers.
class LudoTurnEngine extends StateNotifier<LudoTurnState> {
  LudoTurnEngine(MatchSession session)
      : super(
          LudoTurnState(
            session,
            _restoredPhase(session),
            session.game.activePlayer,
          ),
        );

  static LudoTurnPhase _restoredPhase(MatchSession s) => s.game.winner != null
      ? LudoTurnPhase.completed
      : s.game.diceValue == null
          ? LudoTurnPhase.awaitingRoll
          : LudoTurnPhase.evaluatingMoves;

  LudoTurnState get snapshot => state;
  MatchSession get session => state.session;

  void _phase(LudoTurnPhase phase, [PlayerColor? player]) {
    state = LudoTurnState(session, phase, player ?? state.presentedPlayer);
  }

  MatchCommandResult execute(MatchCommand command) {
    final result = session.execute(command);
    if (!result.accepted) return result;
    final rolls = result.events.whereType<DiceRolled>();
    final moves = result.events.whereType<PawnMoved>();
    state = LudoTurnState(
      result.session,
      rolls.isNotEmpty
          ? LudoTurnPhase.rolling
          : moves.isNotEmpty
              ? LudoTurnPhase.animatingPawn
              : LudoTurnPhase.nextTurn,
      rolls.isNotEmpty ? rolls.first.player : state.presentedPlayer,
    );
    return result;
  }

  /// Returns an equivalent automatic choice, never independently legalizes it.
  int? settleDice() {
    _phase(LudoTurnPhase.evaluatingMoves);
    final game = session.game;
    if (game.diceValue == null) {
      completeMovement();
      return null;
    }
    final legal = game.legalPawnIndices();
    if (legal.isEmpty) {
      _phase(LudoTurnPhase.noMovesPass);
      return null;
    }
    _phase(LudoTurnPhase.awaitingBoardTap);
    if (legal.length == 1) return legal.single;
    if (game.diceValue == 6 &&
        legal.every((i) => game.currentPlayer.pawnProgress[i] == -1)) {
      return legal.first;
    }
    return null;
  }

  void completeMovement() {
    _phase(LudoTurnPhase.resolveTileEvent);
    _phase(LudoTurnPhase.checkVictory);
    if (session.game.winner != null) {
      _phase(LudoTurnPhase.completed, session.game.winner);
    } else {
      _phase(LudoTurnPhase.nextTurn, session.game.activePlayer);
      _phase(LudoTurnPhase.awaitingRoll);
    }
  }

  void reset(MatchSession session) {
    state = LudoTurnState(
      session,
      _restoredPhase(session),
      session.game.activePlayer,
    );
  }
}
