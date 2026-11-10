import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('LudoGame', () {
    test('starts in the required Orange → Green → Magenta → Blue order', () {
      final game = LudoGame.initial();
      expect(game.activePlayer, PlayerColor.orange);
      expect(PlayerColor.orange.next, PlayerColor.green);
      expect(PlayerColor.green.next, PlayerColor.magenta);
      expect(PlayerColor.magenta.next, PlayerColor.blue);
      expect(PlayerColor.blue.next, PlayerColor.orange);
    });

    test('requires a six to release a pawn from home', () {
      final game = LudoGame.initial().roll(5);
      expect(game.legalPawnIndices(), isEmpty);
      expect(() => game.movePawn(0), throwsStateError);
      final six = LudoGame.initial().roll(6);
      expect(six.legalPawnIndices(), [0, 1, 2, 3]);
    });

    test('releases a pawn and grants an extra turn after rolling six', () {
      final moved = LudoGame.initial().roll(6).movePawn(0);
      expect(moved.currentPlayer.pawnProgress[0], 0);
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.diceValue, isNull);
    });

    test('advances to the next player after a non-six move', () {
      final moved = LudoGame.initial().roll(6).movePawn(0).roll(3).movePawn(0);
      expect(
        moved.players.firstWhere((p) => p.color == PlayerColor.orange).pawnProgress[0],
        3,
      );
      expect(moved.activePlayer, PlayerColor.green);
    });

    test('passes to the next player when no pawn can move', () {
      final passed = LudoGame.initial().roll(4).passTurn();
      expect(passed.activePlayer, PlayerColor.green);
      expect(passed.diceValue, isNull);
    });

    test('skips players whose four pawns are already finished', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [0, -1, -1, -1],
          PlayerColor.green: [56, 56, 56, 56],
        },
      );

      final moved = game.roll(1).movePawn(0);
      expect(moved.activePlayer, PlayerColor.magenta);
      expect(
        moved.events.whereType<TurnChanged>().single.to,
        PlayerColor.magenta,
      );
    });

    test('skips a completed player when passing after an unplayable roll', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.green: [56, 56, 56, 56],
        },
      );

      final passed = game.roll(4).passTurn();
      expect(passed.activePlayer, PlayerColor.magenta);
    });

    test('rejects passing while a legal pawn move exists', () {
      final rolled = LudoGame.initial().roll(6);
      expect(() => rolled.passTurn(), throwsStateError);
    });

    test('captures an opponent on an unsafe shared-track cell', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, -1, -1, -1],
        },
      );
      final moved = game.roll(2).movePawn(0);
      expect(moved.currentPlayer.pawnProgress[0], 5);
      expect(
        moved.players.firstWhere((p) => p.color == PlayerColor.green).pawnProgress[0],
        -1,
      );
      expect(moved.activePlayer, PlayerColor.orange);
    });

    test('captures correctly for every player seat orientation', () {
      for (final attacker in PlayerColor.turnOrder) {
        final victim = attacker.next;
        final game = LudoGame.fromProgress(
          activePlayer: attacker,
          pawnProgress: {
            attacker: [3, -1, -1, -1],
            // Progress 44 is the same physical cell as the attacker's
            // landing position at progress 5 for each adjacent seat pair.
            victim: [44, -1, -1, -1],
          },
        );

        final moved = game.roll(2).movePawn(0);
        expect(moved.currentPlayer.pawnProgress[0], 5);
        expect(
          moved.players
              .firstWhere((player) => player.color == victim)
              .pawnProgress[0],
          -1,
          reason: '$attacker should capture $victim across the shared route.',
        );
        expect(moved.activePlayer, attacker);
        expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
      }
    });

    test('every configured safe cell protects a pawn from capture', () {
      var verifiedSafeCells = <int>{};

      for (final attacker in PlayerColor.turnOrder) {
        for (final safeCell in BoardGeometry.safeTrackCells) {
          final attackerDistance =
              (safeCell - attacker.entryIndex + sharedTrackLength) %
                  sharedTrackLength;
          if (attackerDistance == 0 || attackerDistance > 50) continue;

          final attackerProgress = attackerDistance - 1;
          for (final victim in PlayerColor.turnOrder) {
            if (victim == attacker) continue;
            final victimProgress =
                (safeCell - victim.entryIndex + sharedTrackLength) %
                    sharedTrackLength;
            if (victimProgress >= playerTrackLength) continue;

            final game = LudoGame.fromProgress(
              activePlayer: attacker,
              pawnProgress: {
                attacker: [attackerProgress, -1, -1, -1],
                victim: [victimProgress, -1, -1, -1],
              },
            );

            final moved = game.roll(1).movePawn(0);
            expect(
              moved.players
                  .firstWhere((player) => player.color == victim)
                  .pawnProgress[0],
              victimProgress,
              reason: 'Safe cell $safeCell must protect $victim from $attacker.',
            );
            expect(moved.events.whereType<PawnCaptured>(), isEmpty);
            verifiedSafeCells.add(safeCell);
            break;
          }
        }
      }

      expect(verifiedSafeCells, BoardGeometry.safeTrackCells);
    });

    test('default profile requires an exact roll to finish without overshooting', () {
      final exact = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [55, -1, -1, -1],
        },
      ).roll(1);

      expect(exact.legalPawnIndices(), [0]);
      final finished = exact.movePawn(0);
      final finishedOrange = finished.players.firstWhere(
        (player) => player.color == PlayerColor.orange,
      );
      expect(finishedOrange.pawnProgress[0], 56);
      expect(finished.winner, isNull);

      final overshoot = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [55, -1, -1, -1],
        },
      ).roll(2);
      expect(overshoot.legalPawnIndices(), isEmpty);
      expect(() => overshoot.movePawn(0), throwsStateError);
      // A rejected action cannot mutate the immutable pre-action snapshot.
      expect(overshoot.diceValue, 2);
      expect(overshoot.currentPlayer.pawnProgress[0], 55);
      final passed = overshoot.passTurn();
      expect(
        passed.players
            .firstWhere((player) => player.color == PlayerColor.orange)
            .pawnProgress[0],
        55,
      );
      expect(passed.activePlayer, PlayerColor.green);
    },);

    test('does not capture on a safe shared-track cell', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [47, -1, -1, -1],
        },
      );
      final moved = game.roll(5).movePawn(0);
      expect(
        moved.players.firstWhere((p) => p.color == PlayerColor.green).pawnProgress[0],
        47,
      );
      expect(moved.activePlayer, PlayerColor.green);
    });

    test('enters the home lane after 51 shared-track positions', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [50, -1, -1, -1],
        },
      );
      final moved = game.roll(1).movePawn(0);
      expect(
        moved.players.firstWhere((p) => p.color == PlayerColor.orange).pawnProgress[0],
        51,
      );
    });

    test('marks the winner only after all four pawns finish', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [56, 56, 56, 55],
        },
      );
      final moved = game.roll(1).movePawn(3);
      expect(moved.winner, PlayerColor.orange);
    });

    test('rejects dice values outside 1..6', () {
      expect(() => LudoGame.initial().roll(0), throwsArgumentError);
      expect(() => LudoGame.initial().roll(7), throwsArgumentError);
    });

    test('safe cells are the four coloured starts and four artwork stars', () {
      expect(BoardGeometry.startTrackCells, {0, 13, 26, 39});
      expect(BoardGeometry.starTrackCells, {8, 21, 34, 47});
      expect(
        BoardGeometry.safeTrackCells,
        BoardGeometry.startTrackCells.union(BoardGeometry.starTrackCells),
      );

      // Route IDs and logical 15x15 cells, matched to the canonical artwork.
      expect(BoardGeometry.sharedTrack[0], const BoardCell(1, 6));
      expect(BoardGeometry.sharedTrack[8], const BoardCell(6, 2));
      expect(BoardGeometry.sharedTrack[13], const BoardCell(8, 1));
      expect(BoardGeometry.sharedTrack[21], const BoardCell(12, 6));
      expect(BoardGeometry.sharedTrack[26], const BoardCell(13, 8));
      expect(BoardGeometry.sharedTrack[34], const BoardCell(8, 12));
      expect(BoardGeometry.sharedTrack[39], const BoardCell(6, 13));
      expect(BoardGeometry.sharedTrack[47], const BoardCell(2, 8));
    });

    test('Classic blockade prevents passing through an opponent pair', () {
      final rolled = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, 10, -1, -1],
          // Green progress 44 maps to Orange's physical track cell 5.
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(3);

      expect(
        rolled.evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (move) => move.reason,
          'reason',
          MoveInvalidReason.pathBlockedByBlockade,
        ),
      );
      // The player must choose another legal pawn when one exists.
      expect(rolled.legalPawnIndices(), [1]);
      final moved = rolled.movePawn(1);
      expect(moved.currentPlayer.pawnProgress[1], 13);
      expect(moved.activePlayer, PlayerColor.green);
    });

    test('Classic passes the turn when every pawn is blocked by a blockade', () {
      final rolled = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(3);

      expect(rolled.legalPawnIndices(), isEmpty);
      expect(rolled.awaitingPass, isTrue);
      final passed = rolled.passTurn();
      expect(passed.activePlayer, PlayerColor.green);
      expect(passed.diceValue, isNull);
    },);

    test('Classic blockade does not prevent passing through own pawns', () {
      final rolled = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, 5, -1, -1],
        },
      ).roll(3);

      expect(rolled.legalPawnIndices(), contains(0));
      expect(rolled.evaluatePawnMove(0), isA<ValidMove>());
    });

    test('Classic profile ends the turn on the third consecutive six', () {
      var game = LudoGame.initial(ruleProfile: LudoRuleProfile.classicV1);
      game = game.roll(6).movePawn(0);
      game = game.roll(6).movePawn(0);

      final penalized = game.roll(6);
      expect(penalized.activePlayer, PlayerColor.green);
      expect(penalized.diceValue, isNull);
      expect(penalized.consecutiveSixes, 0);
      expect(penalized.events, [
        isA<DiceRolled>(),
        isA<ConsecutiveSixPenalty>(),
        isA<TurnChanged>(),
      ]);
      expect(penalized.stateVersion, game.stateVersion + 1);
    });

    test('Classic rejects landing on a protected pair of opponent pawns', () {
      final rolled = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          // Both Green pawns occupy the same physical cell as Orange 5.
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(2);

      final result = rolled.evaluatePawnMove(0);
      expect(
        result,
        isA<InvalidMove>().having(
          (move) => move.reason,
          'reason',
          MoveInvalidReason.landingOnProtectedStack,
        ),
      );
      expect(rolled.legalPawnIndices(), isEmpty);
      expect(rolled.currentPlayer.pawnProgress[0], 3);
      expect(
        () => rolled.movePawn(0),
        throwsStateError,
      );
    });

    test('Classic profile grants an extra turn for reaching final home', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [55, -1, -1, -1],
        },
      );

      final moved = game.roll(1).movePawn(0);
      expect(moved.currentPlayer.pawnProgress[0], 56);
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.winner, isNull);
      expect(moved.events.first, isA<PawnMoved>());
    });

    test('Classic profile grants one bonus turn after a capture', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          // Green progress 44 maps to the same physical cell as Orange 5.
          PlayerColor.green: [44, -1, -1, -1],
        },
      );

      final moved = game.roll(2).movePawn(0);
      expect(moved.currentPlayer.pawnProgress[0], 5);
      expect(
        moved.players
            .firstWhere((p) => p.color == PlayerColor.green)
            .pawnProgress[0],
        -1,
      );
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
    });

    test(
      'Classic profile rejects overshooting exact finish and passes the turn',
      () {
        final game = LudoGame.fromProgress(
          activePlayer: PlayerColor.orange,
          ruleProfile: LudoRuleProfile.classicV1,
          pawnProgress: {
            PlayerColor.orange: [55, -1, -1, -1],
          },
        ).roll(2);

        expect(game.legalPawnIndices(), isEmpty);
        final passed = game.passTurn();
        expect(passed.activePlayer, PlayerColor.green);
        expect(
          passed.currentPlayer.pawnProgress,
          [-1, -1, -1, -1],
        );
      },
    );

    test('Classic consecutive-six counter resets after a non-six roll', () {
      var game = LudoGame.initial(ruleProfile: LudoRuleProfile.classicV1);
      game = game.roll(6).movePawn(0);
      game = game.roll(6).movePawn(0);
      game = game.roll(2).movePawn(0);
      expect(game.consecutiveSixes, 0);

      game = game.roll(6).movePawn(0);
      game = game.roll(6).movePawn(0);
      final nextSix = game.roll(6);
      expect(nextSix.activePlayer, PlayerColor.magenta);
      expect(nextSix.currentPlayer.pawnProgress, [-1, -1, -1, -1]);
    });

    test('Classic bonus conditions produce only one retained turn', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          // Green progress 48 maps to Orange's landing cell after a six.
          PlayerColor.green: [48, -1, -1, -1],
        },
      );

      // A six and a capture are both bonus conditions; the turn is not stacked.
      final moved = game.roll(6).movePawn(0);
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.diceValue, isNull);
      expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
      expect(moved.events.whereType<ExtraTurnGranted>(), hasLength(1));
    });

    test('accepted transitions increment state version and reject stale commands', () {
      final initial = LudoGame.initial();
      final rolled = initial.roll(
        6,
        expectedStateVersion: 0,
        commandId: 'roll-orange-1',
      );
      expect(rolled.stateVersion, 1);
      expect(rolled.events.single, isA<DiceRolled>());
      expect(
        () => rolled.movePawn(0, expectedStateVersion: 0),
        throwsStateError,
      );
      expect(
        () => rolled.movePawn(0, commandId: 'roll-orange-1'),
        throwsStateError,
      );

      final moved = rolled.movePawn(
        0,
        expectedStateVersion: 1,
        commandId: 'move-orange-pawn-0',
      );
      expect(moved.stateVersion, 2);
      expect(moved.appliedCommandIds, {
        'roll-orange-1',
        'move-orange-pawn-0',
      });
    },);

    test('transition event ordering is deterministic for a capture', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, -1, -1, -1],
        },
      );

      final moved = game.roll(2).movePawn(0);
      expect(moved.events.map((event) => event.runtimeType).toList(), [
        PawnMoved,
        PawnCaptured,
        ExtraTurnGranted,
      ]);
      expect(moved.events.map((event) => event.sequence).toList(), [0, 1, 2]);
    });


    test('stress-runs at least 2500 deterministic transitions without invariant drift', () {
      var game = LudoGame.initial();
      var commandNumber = 0;
      var totalTransitions = 0;
      var matchNumber = 0;
      var turn = 0;

      void verifySnapshot(LudoGame snapshot) {
        expect(snapshot.players.length, 4);
        expect(
          snapshot.players.map((player) => player.color).toSet(),
          PlayerColor.turnOrder.toSet(),
        );
        for (final player in snapshot.players) {
          expect(player.pawnProgress.length, 4);
          expect(
            player.pawnProgress.every(
              (progress) => progress >= -1 && progress <= 56,
            ),
            isTrue,
          );
        }
        expect(snapshot.stateVersion, commandNumber);
        expect(snapshot.appliedCommandIds.length, commandNumber);
        expect(
          snapshot.events.map((event) => event.sequence).toList(),
          List<int>.generate(snapshot.events.length, (index) => index),
        );
        expect(
          snapshot.events.every(
            (event) => event.stateVersion == snapshot.stateVersion,
          ),
          isTrue,
        );
      }

      while (totalTransitions < 2500) {
        final roll = (turn * 17 + 5) % 6 + 1;
        final beforeRollVersion = game.stateVersion;
        game = game.roll(
          roll,
          expectedStateVersion: beforeRollVersion,
          commandId: 'stress-$matchNumber-roll-$turn',
        );
        commandNumber++;
        totalTransitions++;
        verifySnapshot(game);

        if (game.diceValue != null) {
          final legal = game.legalPawnIndices();
          final beforeActionVersion = game.stateVersion;
          if (legal.isEmpty) {
            game = game.passTurn(
              expectedStateVersion: beforeActionVersion,
              commandId: 'stress-$matchNumber-pass-$turn',
            );
          } else {
            game = game.movePawn(
              legal[turn % legal.length],
              expectedStateVersion: beforeActionVersion,
              commandId: 'stress-$matchNumber-move-$turn',
            );
          }
          commandNumber++;
          totalTransitions++;
          verifySnapshot(game);
        }

        if (game.winner != null) {
          matchNumber++;
          commandNumber = 0;
          game = LudoGame.initial();
        }
        turn++;
      }

      expect(totalTransitions, greaterThanOrEqualTo(2500));
    },);

    test('versioned snapshot round-trips an accepted match and pending roll', () {
      final game = LudoGame.initial(ruleProfile: LudoRuleProfile.classicV1)
          .roll(
            6,
            expectedStateVersion: 0,
            commandId: 'persisted-roll-1',
          )
          .movePawn(
            0,
            expectedStateVersion: 1,
            commandId: 'persisted-move-1',
          )
          .roll(
            3,
            expectedStateVersion: 2,
            commandId: 'persisted-roll-2',
          );

      final restored = LudoGame.decodeSnapshot(game.encodeSnapshot());

      expect(restored.players, hasLength(4));
      for (final color in PlayerColor.turnOrder) {
        expect(
          restored.players
              .firstWhere((player) => player.color == color)
              .pawnProgress,
          game.players
              .firstWhere((player) => player.color == color)
              .pawnProgress,
        );
      }
      expect(restored.activePlayer, game.activePlayer);
      expect(restored.diceValue, game.diceValue);
      expect(restored.winner, game.winner);
      expect(restored.ruleProfile, LudoRuleProfile.classicV1);
      expect(restored.stateVersion, game.stateVersion);
      expect(restored.consecutiveSixes, game.consecutiveSixes);
      expect(restored.appliedCommandIds, game.appliedCommandIds);
      expect(restored.events, isEmpty);

      expect(
        () => restored.movePawn(
          0,
          expectedStateVersion: restored.stateVersion,
          commandId: 'persisted-roll-1',
        ),
        throwsStateError,
      );
    },);

    test('schema-v1 snapshots migrate with their original capture behaviour', () {
      final snapshot = LudoGame.initial(
        ruleProfile: LudoRuleProfile.classicV1,
      ).toSnapshot();
      snapshot['schemaVersion'] = 1;
      final profile = snapshot['ruleProfile']! as Map<String, Object?>;
      profile.remove('captureOnlySingleOpponentPawn');

      final restored = LudoGame.fromSnapshot(snapshot);

      expect(restored.ruleProfile.id, 'classic');
      expect(restored.ruleProfile.captureOnlySingleOpponentPawn, isFalse);
    },);

    test('snapshot codec rejects unsupported schema and malformed progress', () {
      expect(
        () => LudoGame.fromSnapshot({'schemaVersion': 99}),
        throwsFormatException,
      );
      final snapshot = LudoGame.initial().toSnapshot();
      final players = snapshot['players']! as List<Map<String, Object?>>;
      players[0] = {
        'color': 'orange',
        'pawnProgress': [57, -1, -1, -1],
      };
      expect(
        () => LudoGame.fromSnapshot(snapshot),
        throwsArgumentError,
      );
    },);

    test('published game snapshots and collections cannot be mutated', () {
      final game = LudoGame.initial().roll(6);
      expect(
        () => game.players.add(LudoPlayer(PlayerColor.green)),
        throwsUnsupportedError,
      );
      expect(
        () => game.currentPlayer.pawnProgress[0] = 3,
        throwsUnsupportedError,
      );
      expect(
        () => game.events.add(const DiceRolled(99, 99, PlayerColor.orange, 6)),
        throwsUnsupportedError,
      );
      expect(
        () => game.appliedCommandIds.add('external-mutation'),
        throwsUnsupportedError,
      );
    });

    test('compatibility profile snapshot preserves more than two consecutive sixes', () {
      var game = LudoGame.initial();
      for (var index = 0; index < 3; index++) {
        game = game.roll(6).movePawn(0);
      }

      expect(game.consecutiveSixes, 3);
      final restored = LudoGame.decodeSnapshot(game.encodeSnapshot());
      expect(restored.consecutiveSixes, 3);
      expect(restored.ruleProfile, LudoRuleProfile.currentV1);
    },);

    test('Classic snapshot rejects an impossible post-penalty six counter', () {
      final snapshot = LudoGame.initial(
        ruleProfile: LudoRuleProfile.classicV1,
      ).toSnapshot()
        ..['consecutiveSixes'] = 3;

      expect(
        () => LudoGame.fromSnapshot(snapshot),
        throwsFormatException,
      );
    });

    test('default compatibility profile preserves existing six behaviour', () {
      var game = LudoGame.initial();
      game = game.roll(6).movePawn(0);
      game = game.roll(6).movePawn(0);
      final thirdSix = game.roll(6);
      expect(thirdSix.activePlayer, PlayerColor.orange);
      expect(thirdSix.diceValue, 6);
    });

    test('invalid dice is a structured move-evaluation result', () {
      final game = LudoGame.initial().roll(3);
      expect(
        game.evaluatePawnMove(0, roll: 0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.invalidDice,
        ),
      );
      expect(
        game.evaluatePawnMove(0, roll: 7),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.invalidDice,
        ),
      );
    });

    test('a roll with no legal move emits an explicit pass-phase event', () {
      final rolled = LudoGame.initial().roll(4);
      expect(rolled.awaitingPass, isTrue);
      expect(rolled.events.map((event) => event.runtimeType), [
        DiceRolled,
        NoLegalMoveEvent,
      ]);
      final noMove = rolled.events.last as NoLegalMoveEvent;
      expect(noMove.player, PlayerColor.orange);
      expect(noMove.diceValue, 4);

      final passed = rolled.passTurn();
      expect(passed.awaitingPass, isFalse);
      expect(passed.diceValue, isNull);
      expect(passed.activePlayer, PlayerColor.green);
    });

    test('a six move emits an extra-turn event', () {
      final moved = LudoGame.initial().roll(6).movePawn(0);
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.events.whereType<ExtraTurnGranted>(), hasLength(1));
    });

    test('passing an unplayable six grants the extra roll explicitly', () {
      final rolled = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [55, 55, 55, 55],
        },
      ).roll(6);

      expect(rolled.awaitingPass, isTrue);
      final passed = rolled.passTurn();
      expect(passed.activePlayer, PlayerColor.orange);
      expect(passed.diceValue, isNull);
      expect(passed.events, hasLength(1));
      expect(passed.events.single, isA<ExtraTurnGranted>());
    });

    test('finishing one pawn emits PawnFinished before the bonus event', () {
      final moved = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {PlayerColor.orange: [55, -1, -1, -1]},
      ).roll(1).movePawn(0);

      expect(moved.currentPlayer.pawnProgress[0], 56);
      expect(moved.events.map((event) => event.runtimeType), [
        PawnMoved,
        PawnFinished,
        ExtraTurnGranted,
      ]);
    });

    test('winning emits both compatibility and explicit game-completed events', () {
      final moved = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {PlayerColor.orange: [56, 56, 56, 55]},
      ).roll(1).movePawn(3);

      expect(moved.winner, PlayerColor.orange);
      expect(moved.events.whereType<PlayerWon>(), hasLength(1));
      expect(moved.events.whereType<GameCompleted>(), hasLength(1));
      expect(moved.events.last, isA<GameCompleted>());
    },);

    test('snapshot rejects completed pawns without a matching winner', () {
      final snapshot = LudoGame.initial().toSnapshot();
      final players = snapshot['players']! as List<Map<String, Object?>>;
      players[0] = {
        'color': 'orange',
        'pawnProgress': [56, 56, 56, 56],
      };

      expect(
        () => LudoGame.fromSnapshot(snapshot),
        throwsFormatException,
      );
    });

    test('snapshot rejects a winner who has not completed all pawns', () {
      final snapshot = LudoGame.initial().toSnapshot()
        ..['winner'] = 'orange';

      expect(
        () => LudoGame.fromSnapshot(snapshot),
        throwsFormatException,
      );
    });

    test('snapshot rejects a winner with a pending dice roll', () {
      final snapshot = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {PlayerColor.orange: [56, 56, 56, 56]},
      ).toSnapshot()
        ..['winner'] = 'orange'
        ..['diceValue'] = 2;

      expect(
        () => LudoGame.fromSnapshot(snapshot),
        throwsFormatException,
      );
    });

    test('snapshot rejects unknown player colors as a format error', () {
      final snapshot = LudoGame.initial().toSnapshot();
      snapshot['activePlayer'] = 'purple';

      expect(
        () => LudoGame.fromSnapshot(snapshot),
        throwsFormatException,
      );
    });
  });
}
