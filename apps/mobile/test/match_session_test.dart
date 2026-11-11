import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('MatchSession command boundary', () {
    late MatchSession initial;

    setUp(() {
      initial = MatchSession.local(
        matchId: 'match-1',
        game: LudoGame.initial(),
      );
    });

    RollDiceCommand roll({
      String matchId = 'match-1',
      String? actorId,
      int expectedVersion = 0,
      String commandId = 'roll-1',
      int value = 6,
    }) =>
        RollDiceCommand(
          matchId: matchId,
          actorId: actorId ?? initial.actorFor(PlayerColor.orange),
          expectedStateVersion: expectedVersion,
          commandId: commandId,
          value: value,
        );

    test('accepts a valid roll and exposes ordered domain events', () {
      final result = initial.execute(roll());

      expect(result.accepted, isTrue);
      expect(result.session.game.stateVersion, 1);
      expect(result.session.game.diceValue, 6);
      expect(result.events, hasLength(1));
      expect(result.events.single, isA<DiceRolled>());
      expect(result.rejectionReason, isNull);
    });

    test('rejects a command from the wrong match without mutation', () {
      final result = initial.execute(roll(matchId: 'another-match'));

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, MatchCommandRejectionReason.wrongMatch);
      expect(identical(result.session, initial), isTrue);
      expect(result.session.game.stateVersion, 0);
    });

    test('rejects a command from a non-active actor', () {
      final result = initial.execute(
        roll(actorId: initial.actorFor(PlayerColor.green)),
      );

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, MatchCommandRejectionReason.wrongActor);
      expect(identical(result.session, initial), isTrue);
    });

    test('rejects stale state versions', () {
      final accepted = initial.execute(roll());
      final stale = accepted.session.execute(
        roll(
          expectedVersion: 0,
          commandId: 'stale-roll',
        ),
      );

      expect(stale.accepted, isFalse);
      expect(stale.rejectionReason, MatchCommandRejectionReason.staleState);
      expect(stale.session.game.stateVersion, 1);
    });

    test('rejects duplicate command IDs after an accepted transition', () {
      final accepted = initial.execute(roll());
      final duplicate = accepted.session.execute(roll());

      expect(duplicate.accepted, isFalse);
      expect(
        duplicate.rejectionReason,
        MatchCommandRejectionReason.duplicateCommand,
      );
      expect(duplicate.session.game.stateVersion, 1);
    });

    test('rejects invalid actions without changing the session', () {
      final result = initial.execute(roll(value: 7));

      expect(result.accepted, isFalse);
      expect(
        result.rejectionReason,
        MatchCommandRejectionReason.invalidAction,
      );
      expect(identical(result.session, initial), isTrue);
    });

    test('returns the engine move reason as a typed rejection', () {
      final rolled = initial.execute(roll(value: 2));
      final rejected = rolled.session.execute(
        MovePawnCommand(
          matchId: 'match-1',
          actorId: initial.actorFor(PlayerColor.orange),
          expectedStateVersion: 1,
          commandId: 'move-from-yard',
          pawnIndex: 0,
        ),
      );

      expect(rejected.accepted, isFalse);
      expect(
        rejected.rejectionReason,
        MatchCommandRejectionReason.illegalMove,
      );
      expect(
        rejected.moveInvalidReason,
        MoveInvalidReason.pawnInYardNeedsSix,
      );
      expect(rejected.session.game.stateVersion, 1);
    });

    test('rejects a second roll while a roll is pending', () {
      final rolled = initial.execute(roll());
      final rejected = rolled.session.execute(
        roll(expectedVersion: 1, commandId: 'roll-again'),
      );

      expect(rejected.accepted, isFalse);
      expect(
        rejected.rejectionReason,
        MatchCommandRejectionReason.rollAlreadyPending,
      );
      expect(rejected.session.game.stateVersion, 1);
    });

    test('rejects pass when a legal move is available', () {
      final rolled = initial.execute(roll());
      final rejected = rolled.session.execute(
        PassTurnCommand(
          matchId: 'match-1',
          actorId: initial.actorFor(PlayerColor.orange),
          expectedStateVersion: 1,
          commandId: 'premature-pass',
        ),
      );

      expect(rejected.accepted, isFalse);
      expect(
        rejected.rejectionReason,
        MatchCommandRejectionReason.passNotAllowed,
      );
      expect(rejected.session.game.stateVersion, 1);
    });

    test('routes an automatic no-legal-move pass through the boundary', () {
      final rolled = initial.execute(roll(value: 4));
      expect(rolled.accepted, isTrue);
      final passed = rolled.session.execute(
        PassTurnCommand(
          matchId: 'match-1',
          actorId: initial.actorFor(PlayerColor.orange),
          expectedStateVersion: 1,
          commandId: 'pass-1',
        ),
      );

      expect(passed.accepted, isTrue);
      expect(passed.session.game.activePlayer, PlayerColor.green);
      expect(passed.session.game.diceValue, isNull);
      expect(passed.session.game.stateVersion, 2);
    });

    test('replays accepted commands to the same snapshot and events', () {
      final commands = <MatchCommand>[
        roll(),
        MovePawnCommand(
          matchId: 'match-1',
          actorId: initial.actorFor(PlayerColor.orange),
          expectedStateVersion: 1,
          commandId: 'move-1',
          pawnIndex: 0,
        ),
      ];

      final sequential = commands.fold<MatchSession>(
        initial,
        (session, command) {
          final result = session.execute(command);
          expect(result.accepted, isTrue);
          return result.session;
        },
      );
      final replayed = MatchSession.replay(
        initial: initial,
        commands: commands,
      );

      expect(replayed.game.encodeSnapshot(), sequential.game.encodeSnapshot());
      expect(
        replayed.game.events.map((event) => event.runtimeType).toList(),
        sequential.game.events.map((event) => event.runtimeType).toList(),
      );
      expect(replayed.game.currentPlayer.pawnProgress.first, 0);
      expect(replayed.game.stateVersion, 2);
    });

    test('replay stops at the first rejected command', () {
      final commands = <MatchCommand>[
        roll(),
        roll(
          expectedVersion: 1,
          commandId: 'wrong-actor',
          actorId: initial.actorFor(PlayerColor.green),
        ),
      ];

      expect(
        () => MatchSession.replay(initial: initial, commands: commands),
        throwsStateError,
      );
    });
  });

  test('requires exactly four distinct non-empty seat actor IDs', () {
    expect(
      () => MatchSession(
        matchId: 'match-1',
        game: LudoGame.initial(),
        actorIds: {PlayerColor.orange: 'same'},
      ),
      throwsArgumentError,
    );
    expect(
      () => MatchSession(
        matchId: 'match-1',
        game: LudoGame.initial(),
        actorIds: {
          for (final color in PlayerColor.turnOrder) color: 'same',
        },
      ),
      throwsArgumentError,
    );
  });
}
