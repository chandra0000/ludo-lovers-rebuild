import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_move_presentation_plan.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  MatchMovePresentationPlan present(
    LudoGame game, {
    PlayerColor player = PlayerColor.orange,
    int pawnIndex = 0,
  }) =>
      MatchMovePresentationPlan.fromEvents(
        events: game.events,
        player: player,
        pawnIndex: pawnIndex,
      );

  test('yard release uses the accepted event endpoints, not six UI steps', () {
    final game = LudoGame.initial().roll(6).movePawn(0);
    final plan = present(game);

    expect(plan.player, PlayerColor.orange);
    expect(plan.pawnIndex, 0);
    expect(plan.startProgress, -1);
    expect(plan.endProgress, 0);
    expect(plan.stepCount, 1);
    expect(plan.feedback, isNull);
    expect(plan.captureCount, 0);
    expect(plan.hasCapture, isFalse);
    expect(plan.gameCompleted, isFalse);
    expect(plan.extraTurnGranted, isFalse);
  });

  test('capture feedback includes extra turn only when engine grants it', () {
    LudoGame capture({LudoRuleProfile? profile}) => LudoGame.fromProgress(
          activePlayer: PlayerColor.orange,
          ruleProfile: profile ?? LudoRuleProfile.currentV1,
          pawnProgress: {
            PlayerColor.orange: [3, -1, -1, -1],
            PlayerColor.green: [44, -1, -1, -1],
          },
        ).roll(2).movePawn(0);

    final withBonus = capture();
    expect(withBonus.events.whereType<PawnCaptured>(), hasLength(1));
    expect(withBonus.events.whereType<ExtraTurnGranted>(), hasLength(1));
    expect(present(withBonus).feedback, 'CAPTURE! EXTRA TURN');
    expect(present(withBonus).captureCount, 1);
    expect(present(withBonus).hasCapture, isTrue);
    expect(present(withBonus).extraTurnGranted, isTrue);
    expect(present(withBonus).stepCount, 2);

    final withoutBonus = capture(
      profile: const LudoRuleProfile(
        id: 'no-capture-bonus',
        version: 1,
        extraTurnOnCapture: false,
      ),
    );
    expect(withoutBonus.events.whereType<PawnCaptured>(), hasLength(1));
    expect(withoutBonus.events.whereType<ExtraTurnGranted>(), isEmpty);
    expect(withoutBonus.activePlayer, PlayerColor.green);
    expect(present(withoutBonus).feedback, 'CAPTURE!');
    expect(present(withoutBonus).extraTurnGranted, isFalse);
  });

  test('captures of two unprotected pawns are announced accurately', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [3, -1, -1, -1],
        PlayerColor.green: [44, 44, -1, -1],
      },
    ).roll(2).movePawn(0);

    expect(game.events.whereType<PawnCaptured>(), hasLength(2));
    expect(present(game).feedback, '2 CAPTURES! EXTRA TURN');
    expect(present(game).captureCount, 2);
  });

  test('home arrival only announces a bonus when the rule grants one', () {
    LudoGame finish(LudoRuleProfile profile) => LudoGame.fromProgress(
          activePlayer: PlayerColor.orange,
          ruleProfile: profile,
          pawnProgress: {
            PlayerColor.orange: [55, -1, -1, -1],
          },
        ).roll(1).movePawn(0);

    final current = finish(LudoRuleProfile.currentV1);
    expect(current.events.whereType<PawnFinished>(), hasLength(1));
    expect(present(current).feedback, 'PAWN HOME!');

    final classic = finish(LudoRuleProfile.classicV1);
    expect(classic.events.whereType<ExtraTurnGranted>(), hasLength(1));
    expect(present(classic).feedback, 'PAWN HOME! EXTRA TURN');
  });

  test('final pawn winner overrides finishing and bonus messages', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [56, 56, 56, 55],
      },
    ).roll(1).movePawn(3);

    final plan = present(game, pawnIndex: 3);
    expect(plan.endProgress, 56);
    expect(plan.feedback, 'ORANGE WINS!');
    expect(plan.gameCompleted, isTrue);
    expect(game.events.whereType<GameCompleted>(), hasLength(1));
  });

  test('ordinary extra turn feedback requires an engine event', () {
    final game = LudoGame.initial().roll(6).movePawn(0);
    final plan = present(game);
    final granted = game.events.whereType<ExtraTurnGranted>().any(
      (event) => event.player == PlayerColor.orange,
    );
    expect(plan.extraTurnGranted, granted);
    expect(plan.feedback, granted ? 'EXTRA TURN' : null);
  });

  test('a rejected or mismatched command cannot yield an animation plan', () {
    final rolled = LudoGame.initial().roll(6);
    expect(
      () => present(rolled),
      throwsStateError,
    );
    final moved = rolled.movePawn(1);
    expect(
      () => present(moved, pawnIndex: 0),
      throwsStateError,
    );
  });

  test('duplicate movement events cannot produce a partial animation', () {
    final game = LudoGame.initial().roll(6).movePawn(0);
    final moved = game.events.whereType<PawnMoved>().single;
    expect(
      () => MatchMovePresentationPlan.fromEvents(
        events: [...game.events, moved],
        player: PlayerColor.orange,
        pawnIndex: 0,
      ),
      throwsStateError,
    );
  });

  test('a movement event cannot animate a different player', () {
    final game = LudoGame.initial().roll(6).movePawn(0);
    expect(
      () => MatchMovePresentationPlan.fromEvents(
        events: game.events,
        player: PlayerColor.green,
        pawnIndex: 0,
      ),
      throwsStateError,
    );
  });
}
