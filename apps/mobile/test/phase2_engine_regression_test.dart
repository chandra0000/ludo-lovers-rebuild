import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Phase 2 deterministic engine regressions', () {
    test('a pawn needs six to leave the yard', () {
      final game = LudoGame.initial().roll(3);
      expect(game.awaitingPass, isTrue);
      expect(game.legalPawnIndices(), isEmpty);
      final passed = game.passTurn();
      expect(passed.activePlayer, PlayerColor.green);
      expect(passed.diceValue, isNull);
    });

    test('six enters the track and grants an extra turn', () {
      final rolled = LudoGame.initial().roll(6);
      expect(rolled.legalPawnIndices(), <int>[0, 1, 2, 3]);
      final moved = rolled.movePawn(0);
      expect(moved.currentPlayer.pawnProgress[0], 0);
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.diceValue, isNull);
    });

    test('exact finish rejects overshooting moves', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[55, -1, -1, -1],
        },
      ).roll(2);
      expect(game.legalPawnIndices(), isEmpty);
      expect(game.awaitingPass, isTrue);
    });

    test('exact finish succeeds on the required roll', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[55, -1, -1, -1],
        },
      ).roll(1).movePawn(0);
      expect(
        game.players
            .firstWhere((player) => player.color == PlayerColor.orange)
            .pawnProgress[0],
        finishProgress,
      );
      expect(game.activePlayer, PlayerColor.green);
    });

    test('classic third consecutive six forfeits the turn', () {
      var game = LudoGame.initial(ruleProfile: LudoRuleProfile.classicV1);
      game = game.roll(6).movePawn(0);
      game = game.roll(6).movePawn(0);
      game = game.roll(6);
      expect(game.activePlayer, PlayerColor.green);
      expect(game.diceValue, isNull);
      expect(game.consecutiveSixes, 0);
      expect(game.events.whereType<ConsecutiveSixPenalty>(), hasLength(1));
    });

    test('snapshot preserves a pending roll and command deduplication', () {
      final rolled = LudoGame.initial().roll(
        6,
        commandId: 'roll-one',
        expectedStateVersion: 0,
      );
      final restored = LudoGame.decodeSnapshot(rolled.encodeSnapshot());
      expect(restored.diceValue, 6);
      expect(restored.stateVersion, 1);
      expect(restored.legalPawnIndices(), <int>[0, 1, 2, 3]);
      expect(
        () => restored.movePawn(0, commandId: 'roll-one'),
        throwsStateError,
      );
      expect(
        () => restored.movePawn(0, expectedStateVersion: 0),
        throwsStateError,
      );
      expect(
        restored.movePawn(0, expectedStateVersion: 1).stateVersion,
        2,
      );
    });

    test('saved matches reject duplicate player records', () {
      final snapshot = LudoGame.initial().toSnapshot();
      final players = List<Map<String, Object?>>.from(
        snapshot['players']! as List<Map<String, Object?>>,
      );
      players[1] = Map<String, Object?>.from(players[0]);
      snapshot['players'] = players;
      expect(() => LudoGame.fromSnapshot(snapshot), throwsFormatException);
    });
  });
}
