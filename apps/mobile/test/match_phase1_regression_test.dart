import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_command_controller.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  MatchCommandController controllerFor(LudoGame game, String matchId) {
    return MatchCommandController(
      MatchSession.local(matchId: matchId, game: game),
    );
  }

  MatchCommandResult roll(MatchCommandController controller, int value) {
    final game = controller.game;
    return controller.execute(
      RollDiceCommand(
        matchId: controller.session.matchId,
        actorId: controller.session.actorFor(game.activePlayer),
        expectedStateVersion: game.stateVersion,
        commandId: 'regression-roll-${game.stateVersion}',
        value: value,
      ),
    );
  }

  MatchCommandResult move(MatchCommandController controller, int pawnIndex) {
    final game = controller.game;
    return controller.execute(
      MovePawnCommand(
        matchId: controller.session.matchId,
        actorId: controller.session.actorFor(game.activePlayer),
        expectedStateVersion: game.stateVersion,
        commandId: 'regression-move-${game.stateVersion}',
        pawnIndex: pawnIndex,
      ),
    );
  }

  test('dice six releases a pawn and grants one extra turn', () {
    final controller = controllerFor(LudoGame.initial(), 'six-match');

    expect(roll(controller, 6).accepted, isTrue);
    expect(move(controller, 0).accepted, isTrue);
    expect(controller.game.currentPlayer.pawnProgress[0], 0);
    expect(controller.game.activePlayer, PlayerColor.orange);

    expect(roll(controller, 3).accepted, isTrue);
    expect(move(controller, 0).accepted, isTrue);
    expect(controller.game.currentPlayer.color, PlayerColor.green);
    expect(controller.game.diceValue, isNull);
    expect(controller.game.stateVersion, 4);
  });

  test('no legal pawns require a pass, not an automatic rule bypass', () {
    final controller = controllerFor(LudoGame.initial(), 'pass-match');
    final rolled = roll(controller, 4);
    expect(rolled.accepted, isTrue);
    expect(controller.game.awaitingPass, isTrue);

    final game = controller.game;
    final passed = controller.execute(
      PassTurnCommand(
        matchId: controller.session.matchId,
        actorId: controller.session.actorFor(game.activePlayer),
        expectedStateVersion: game.stateVersion,
        commandId: 'regression-pass-1',
      ),
    );
    expect(passed.accepted, isTrue);
    expect(controller.game.activePlayer, PlayerColor.green);
    expect(controller.game.diceValue, isNull);
  });

  test('capture emits the event and awards the attacker an extra turn', () {
    final controller = controllerFor(
      LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, -1, -1, -1],
        },
      ),
      'capture-match',
    );

    expect(roll(controller, 2).accepted, isTrue);
    final moved = move(controller, 0);
    expect(moved.accepted, isTrue);
    expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
    expect(controller.game.activePlayer, PlayerColor.orange);
    expect(controller.game.currentPlayer.pawnProgress[0], 5);
    expect(
      controller.game.players
          .firstWhere((player) => player.color == PlayerColor.green)
          .pawnProgress[0],
      -1,
    );
  });

  test('winner is final and later commands cannot mutate the match', () {
    final controller = controllerFor(
      LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [56, 56, 56, 55],
        },
      ),
      'win-match',
    );
    expect(roll(controller, 1).accepted, isTrue);
    final won = move(controller, 3);
    expect(won.accepted, isTrue);
    expect(won.events.whereType<GameCompleted>(), hasLength(1));
    expect(controller.game.winner, PlayerColor.orange);

    final snapshot = controller.game.encodeSnapshot();
    final rejected = roll(controller, 6);
    expect(rejected.accepted, isFalse);
    expect(
      rejected.rejectionReason,
      MatchCommandRejectionReason.gameFinished,
    );
    expect(controller.game.encodeSnapshot(), snapshot);
  });

  test('restart rejects actions from the old match identity', () {
    final controller = controllerFor(LudoGame.initial(), 'old-match');
    final oldCommand = RollDiceCommand(
      matchId: controller.session.matchId,
      actorId: controller.session.actorFor(PlayerColor.orange),
      expectedStateVersion: 0,
      commandId: 'old-roll',
      value: 6,
    );
    controller.reset(
      MatchSession.local(matchId: 'new-match', game: LudoGame.initial()),
    );
    final rejected = controller.execute(oldCommand);
    expect(rejected.accepted, isFalse);
    expect(
      rejected.rejectionReason,
      MatchCommandRejectionReason.wrongMatch,
    );
    expect(controller.game.stateVersion, 0);
    expect(controller.game.diceValue, isNull);
  });
}
