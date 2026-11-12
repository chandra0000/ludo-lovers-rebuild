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

  test('reset replaces the session without retaining old match state', () {
    final controller = MatchCommandController(initial('match-a'));
    final replacement = initial('match-b');
    controller.reset(replacement);
    expect(controller.session, same(replacement));
    expect(controller.session.matchId, 'match-b');
  });
}
