import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_command_controller.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  MatchSession initial(String id) => MatchSession.local(
        matchId: id,
        game: LudoGame.initial(),
      );

  test('accepted command updates controller through authoritative session', () {
    final controller = MatchCommandController(initial('match-a'));
    final before = controller.game;
    final result = controller.execute(
      RollDiceCommand(
        matchId: controller.session.matchId,
        actorId: controller.session.actorFor(PlayerColor.orange),
        expectedStateVersion: before.stateVersion,
        commandId: 'roll-1',
        value: 6,
      ),
    );
    expect(result.accepted, isTrue);
    expect(controller.game.stateVersion, before.stateVersion + 1);
    expect(controller.game.diceValue, 6);
  });

  test('rejected command never mutates controller', () {
    final controller = MatchCommandController(initial('match-a'));
    final before = controller.session;
    final result = controller.execute(
      RollDiceCommand(
        matchId: 'wrong-match',
        actorId: before.actorFor(PlayerColor.orange),
        expectedStateVersion: before.game.stateVersion,
        commandId: 'bad-roll',
        value: 3,
      ),
    );
    expect(result.accepted, isFalse);
    expect(controller.session, same(before));
  });

  test('command builders use current match ID, actor and version', () {
    final controller = MatchCommandController(initial('match-a'));
    final roll = controller.buildRoll(value: 6, isAi: false, aiSeed: 1);
    expect(roll.matchId, 'match-a');
    expect(roll.actorId, controller.session.actorFor(PlayerColor.orange));
    expect(roll.expectedStateVersion, 0);
    expect(roll.commandId, 'match-0-roll');
    expect(controller.execute(roll).accepted, isTrue);

    final move = controller.buildMove(0);
    expect(move.matchId, 'match-a');
    expect(move.expectedStateVersion, 1);
    expect(move.commandId, 'match-1-move-0');
    expect(controller.execute(move).accepted, isTrue);

    final pass = controller.buildPass();
    expect(pass.expectedStateVersion, 2);
    expect(pass.commandId, 'match-2-pass');

    final aiRoll = controller.buildRoll(value: 4, isAi: true, aiSeed: 42);
    expect(aiRoll.commandId, 'ai-42-2-roll');

    controller.reset(initial('match-b'));
    final restarted = controller.buildRoll(value: 6, isAi: false, aiSeed: 1);
    expect(restarted.matchId, 'match-b');
    expect(restarted.expectedStateVersion, 0);
  });

  test('reset replaces the session without retaining old match state', () {
    final controller = MatchCommandController(initial('match-a'));
    final replacement = initial('match-b');
    controller.reset(replacement);
    expect(controller.session, same(replacement));
    expect(controller.session.matchId, 'match-b');
  });
}
