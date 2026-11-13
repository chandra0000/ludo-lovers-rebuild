import 'dart:math' as math;

import '../../game/application/match_session.dart';
import '../../game/domain/player_color.dart';

/// Pure AI turn policy. Scheduling and visual effects remain in the widget;
/// all game transitions remain authoritative in MatchSession.
class MatchAiTurnPolicy {
  const MatchAiTurnPolicy();

  bool canSchedule({
    required MatchSession session,
    required Set<PlayerColor> aiPlayers,
    required bool isAppResumed,
    required bool isScheduled,
    required bool isMovementAnimating,
    required bool isDiceAnimating,
  }) {
    final game = session.game;
    return isAppResumed &&
        aiPlayers.contains(game.activePlayer) &&
        game.winner == null &&
        game.diceValue == null &&
        !isScheduled &&
        !isMovementAnimating &&
        !isDiceAnimating;
  }

  RollDiceCommand createRoll({
    required MatchSession session,
    required int aiSeed,
  }) {
    final game = session.game;
    return RollDiceCommand(
      matchId: session.matchId,
      actorId: session.actorFor(game.activePlayer),
      expectedStateVersion: game.stateVersion,
      commandId: 'ai-$aiSeed-${game.stateVersion}-roll',
      value: math.Random(aiSeed ^ game.stateVersion).nextInt(6) + 1,
    );
  }
}
