import 'package:flutter_test/flutter_test.dart';
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
  });
}
