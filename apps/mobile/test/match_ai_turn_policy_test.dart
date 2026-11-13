import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_ai_turn_policy.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  const policy = MatchAiTurnPolicy();
  MatchSession initial() => MatchSession.local(
        matchId: 'test-ai',
        game: LudoGame.initial(),
      );

  test('AI only schedules when eligible and foregrounded', () {
    final session = initial();
    bool eligible({bool resumed = true, bool scheduled = false}) =>
        policy.canSchedule(
          session: session,
          aiPlayers: {session.game.activePlayer},
          isAppResumed: resumed,
          isScheduled: scheduled,
          isMovementAnimating: false,
          isDiceAnimating: false,
        );
    expect(eligible(), isTrue);
    expect(eligible(resumed: false), isFalse);
    expect(eligible(scheduled: true), isFalse);
    expect(
      policy.canSchedule(
        session: session,
        aiPlayers: const <PlayerColor>{},
        isAppResumed: true,
        isScheduled: false,
        isMovementAnimating: false,
        isDiceAnimating: false,
      ),
      isFalse,
    );
  });

  test('AI roll command is deterministic for the same state', () {
    final session = initial();
    final first = policy.createRoll(session: session, aiSeed: 123);
    final second = policy.createRoll(session: session, aiSeed: 123);
    expect(first.value, second.value);
    expect(first.commandId, second.commandId);
    expect(first.expectedStateVersion, session.game.stateVersion);
    expect(first.actorId, session.actorFor(session.game.activePlayer));
    expect(first.value, inInclusiveRange(1, 6));
  });
}
