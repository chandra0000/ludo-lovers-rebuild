import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  MatchSession seeded(Map<PlayerColor, List<int>> progress) =>
      MatchSession.local(
        matchId: 'classic-acceptance',
        game: LudoGame.fromProgress(
          activePlayer: PlayerColor.orange,
          ruleProfile: LudoRuleProfile.classicV1,
          pawnProgress: progress,
        ),
      );

  MatchCommandResult roll(MatchSession session, int value, String id) =>
      session.execute(
        RollDiceCommand(
          matchId: session.matchId,
          actorId: session.actorFor(session.game.activePlayer),
          expectedStateVersion: session.game.stateVersion,
          commandId: id,
          value: value,
        ),
      );

  MatchCommandResult move(MatchSession session, int index, String id) =>
      session.execute(
        MovePawnCommand(
          matchId: session.matchId,
          actorId: session.actorFor(session.game.activePlayer),
          expectedStateVersion: session.game.stateVersion,
          commandId: id,
          pawnIndex: index,
        ),
      );

  test('third consecutive six forfeits turn without moving any pawn', () {
    var session = seeded({
      PlayerColor.orange: [0, -1, -1, -1],
    });
    for (var i = 0; i < 2; i++) {
      final rolled = roll(session, 6, 'six-$i');
      expect(rolled.accepted, isTrue);
      final moved = move(rolled.session, 0, 'move-$i');
      expect(moved.accepted, isTrue);
      session = moved.session;
      expect(session.game.activePlayer, PlayerColor.orange);
    }
    final before = session.game.currentPlayer.pawnProgress;
    final penalty = roll(session, 6, 'third-six');
    expect(penalty.accepted, isTrue);
    expect(penalty.session.game.activePlayer, PlayerColor.green);
    expect(penalty.session.game.diceValue, isNull);
    expect(penalty.session.game.players.first.pawnProgress, before);
    expect(penalty.events.whereType<ConsecutiveSixPenalty>(), hasLength(1));
    final duplicate = penalty.session.execute(
      RollDiceCommand(
        matchId: session.matchId,
        actorId: session.actorFor(PlayerColor.orange),
        expectedStateVersion: session.game.stateVersion,
        commandId: 'third-six',
        value: 6,
      ),
    );
    expect(
      duplicate.rejectionReason,
      MatchCommandRejectionReason.duplicateCommand,
    );
  });

  test('hard blockade rejects intermediate path via session boundary', () {
    final session = seeded({
      PlayerColor.orange: [3, -1, -1, -1],
      PlayerColor.green: [44, 44, -1, -1],
    });
    final rolled = roll(session, 4, 'block-roll');
    expect(rolled.accepted, isTrue);
    final blocked = move(rolled.session, 0, 'blocked-move');
    expect(blocked.accepted, isFalse);
    expect(blocked.rejectionReason, MatchCommandRejectionReason.illegalMove);
    expect(
      blocked.moveInvalidReason,
      MoveInvalidReason.pathBlockedByBlockade,
    );
    expect(identical(blocked.session, rolled.session), isTrue);
  });

  test('protected destination stack rejects capture', () {
    final rolled = roll(
      seeded({
        PlayerColor.orange: [3, -1, -1, -1],
        PlayerColor.green: [44, 44, -1, -1],
      }),
      2,
      'stack-roll',
    );
    final blocked = move(rolled.session, 0, 'stack-move');
    expect(blocked.accepted, isFalse);
    expect(
      blocked.moveInvalidReason,
      MoveInvalidReason.landingOnProtectedStack,
    );
  });

  test('capture awards extra turn through accepted commands', () {
    final rolled = roll(
      seeded({
        PlayerColor.orange: [3, -1, -1, -1],
        PlayerColor.green: [44, -1, -1, -1],
      }),
      2,
      'capture-roll',
    );
    final moved = move(rolled.session, 0, 'capture-move');
    expect(moved.accepted, isTrue);
    expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
    expect(moved.events.whereType<ExtraTurnGranted>(), hasLength(1));
    expect(moved.session.game.activePlayer, PlayerColor.orange);
  });

  test('finishing a pawn awards extra turn under classic profile', () {
    final rolled = roll(
      seeded({
        PlayerColor.orange: [55, -1, -1, -1],
      }),
      1,
      'finish-roll',
    );
    final moved = move(rolled.session, 0, 'finish-move');
    expect(moved.accepted, isTrue);
    expect(moved.events.whereType<PawnFinished>(), hasLength(1));
    expect(moved.events.whereType<ExtraTurnGranted>(), hasLength(1));
    expect(moved.session.game.activePlayer, PlayerColor.orange);
  });

  test('rolling six and moving awards another turn', () {
    final rolled = roll(seeded({}), 6, 'six-roll');
    final moved = move(rolled.session, 0, 'six-move');
    expect(moved.accepted, isTrue);
    expect(moved.session.game.activePlayer, PlayerColor.orange);
    expect(moved.events.whereType<ExtraTurnGranted>(), hasLength(1));
  });
}
