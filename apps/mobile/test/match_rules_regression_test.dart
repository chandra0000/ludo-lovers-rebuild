import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Classic match rules regression', () {
    test('a pawn cannot leave its yard without a six for any player', () {
      for (final color in PlayerColor.turnOrder) {
        for (var roll = 1; roll <= 5; roll++) {
          final game = LudoGame.fromProgress(
            activePlayer: color,
            pawnProgress: const {},
          ).roll(roll);
          expect(game.legalPawnIndices(), isEmpty);
          expect(
            () => game.movePawn(0),
            throwsStateError,
          );
        }
        final six = LudoGame.fromProgress(
          activePlayer: color,
          pawnProgress: const {},
        ).roll(6);
        expect(six.legalPawnIndices(), [0, 1, 2, 3]);
        final entered = six.movePawn(0);
        expect(
          entered.players
              .firstWhere((player) => player.color == color)
              .pawnProgress[0],
          0,
        );
        expect(entered.activePlayer, color);
      }
    });

    test('exact finish and overshoot work identically for all seats', () {
      for (final color in PlayerColor.turnOrder) {
        final game = LudoGame.fromProgress(
          activePlayer: color,
          pawnProgress: {
            color: [55, -1, -1, -1],
          },
        );
        final exact = game.roll(1).movePawn(0);
        expect(
          exact.players
              .firstWhere((player) => player.color == color)
              .pawnProgress[0],
          56,
        );
        final overshoot = game.roll(2);
        expect(overshoot.legalPawnIndices(), isEmpty);
        expect(() => overshoot.movePawn(0), throwsStateError);
      }
    });

    test('invalid actions never change the prior immutable game', () {
      final initial = LudoGame.initial();
      final rolled = initial.roll(2);
      expect(() => rolled.movePawn(0), throwsStateError);
      expect(initial.diceValue, isNull);
      expect(initial.currentPlayer.pawnProgress, [-1, -1, -1, -1]);
      expect(rolled.diceValue, 2);
      expect(rolled.currentPlayer.pawnProgress, [-1, -1, -1, -1]);
    });
  });
}
