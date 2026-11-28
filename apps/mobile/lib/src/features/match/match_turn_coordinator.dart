import '../../game/application/match_session.dart';
import '../../game/domain/ai/seeded_ludo_ai.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import 'match_ai_scheduler.dart';
import 'match_ai_turn_policy.dart';
import 'match_command_controller.dart';
import 'match_turn_resolution_controller.dart';

/// Coordinates accepted commands and bounded presentation callbacks, never rules.
/// Engine-owned legal moves, events and versions remain authoritative.
class MatchTurnCoordinator {
  MatchTurnCoordinator({
    required this.controller,
    required Set<PlayerColor> aiPlayers,
    required this.aiSeed,
    required this.difficulty,
    required this.isActive,
    required this.movementBusy,
    required this.diceBusy,
    required this.rollHuman,
    required this.execute,
    required this.onRollAccepted,
    required this.onMoveAccepted,
    required this.onDiceSettled,
    required this.onChanged,
    required this.onPenalty,
  }) : aiPlayers = Set.unmodifiable(aiPlayers);

  final MatchCommandController controller;
  final Set<PlayerColor> aiPlayers;
  final int aiSeed;
  final LudoAiDifficulty difficulty;
  final bool Function() isActive;
  final bool Function() movementBusy;
  final bool Function() diceBusy;
  final int Function() rollHuman;
  final MatchCommandResult Function(MatchCommand) execute;
  final void Function(LudoGame) onRollAccepted;
  final void Function(LudoGame, int, List<LudoGameEvent>) onMoveAccepted;
  final void Function() onDiceSettled;
  final void Function() onChanged;
  final void Function() onPenalty;
  final resolution = MatchTurnResolutionController();
  final aiScheduler = MatchAiScheduler();
  final _aiPolicy = const MatchAiTurnPolicy();
  final _ai = const SeededLudoAi();
  bool _disposed = false;
  bool get _active => !_disposed && isActive();
  LudoGame get _game => controller.game;

  void scheduleAi() {
    if (!_active ||
        !_aiPolicy.canSchedule(
          session: controller.session,
          aiPlayers: aiPlayers,
          isAppResumed: _active,
          isScheduled: aiScheduler.isScheduled,
          isMovementAnimating: movementBusy(),
          isDiceAnimating: diceBusy(),
        )) {
      return;
    }
    aiScheduler.schedule(() {
      if (!_active ||
          !aiPlayers.contains(_game.activePlayer) ||
          _game.winner != null ||
          _game.diceValue != null ||
          movementBusy() ||
          diceBusy()) {
        return;
      }
      final result = execute(
        _aiPolicy.createRoll(session: controller.session, aiSeed: aiSeed),
      );
      if (!result.accepted) return;
      onRollAccepted(_game);
      if (_game.diceValue == null) {
        onPenalty();
        scheduleAi();
      }
    });
  }

  bool roll() {
    if (!_active ||
        aiPlayers.contains(_game.activePlayer) ||
        _game.diceValue != null ||
        _game.winner != null ||
        movementBusy() ||
        diceBusy()) {
      return false;
    }
    final result = execute(
      controller.buildRoll(value: rollHuman(), isAi: false, aiSeed: aiSeed),
    );
    if (!result.accepted) return false;
    onRollAccepted(_game);
    if (_game.events.whereType<ConsecutiveSixPenalty>().isNotEmpty) {
      onPenalty();
      scheduleAi();
    }
    return true;
  }

  void completeDice() {
    if (!_active || !diceBusy()) return;
    final legal = _game.legalPawnIndices();
    onDiceSettled();
    if (_game.diceValue == null) {
      scheduleAi();
      return;
    }
    if (legal.isEmpty) {
      resolution.schedulePass(
        matchId: controller.session.matchId,
        stateVersion: _game.stateVersion,
        currentMatchId: () => controller.session.matchId,
        currentStateVersion: () => _game.stateVersion,
        canExecute: () => _active && _game.diceValue != null,
        onReady: () {
          final accepted = execute(controller.buildPass()).accepted;
          onChanged();
          if (accepted) scheduleAi();
        },
      );
      onChanged();
      return;
    }
    final selected = aiPlayers.contains(_game.activePlayer)
        ? _ai.choosePawn(
            _game,
            seed: aiSeed ^ _game.stateVersion,
            difficulty: difficulty,
          )
        : legal.length == 1
            ? legal.single
            : null;
    if (selected != null) {
      resolution.schedulePawn(
        matchId: controller.session.matchId,
        stateVersion: _game.stateVersion,
        currentMatchId: () => controller.session.matchId,
        currentStateVersion: () => _game.stateVersion,
        canExecute: () => _active && _game.diceValue != null && !movementBusy(),
        onReady: () {
          onChanged();
          move(selected);
        },
      );
      onChanged();
    }
  }

  void move(int pawnIndex) {
    if (!_active ||
        diceBusy() ||
        resolution.isPending ||
        !_game.legalPawnIndices().contains(pawnIndex)) {
      return;
    }
    final beforeMove = _game;
    final result = execute(controller.buildMove(pawnIndex));
    if (result.accepted) onMoveAccepted(beforeMove, pawnIndex, result.events);
  }

  void cancelPending() {
    aiScheduler.cancel();
    resolution.cancel();
  }

  void dispose() {
    _disposed = true;
    cancelPending();
  }
}
