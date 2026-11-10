import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('LudoGame.evaluatePawnMove', () {
    test('soft stacks can be passed through when hard blockade is disabled', () {
      const profile = LudoRuleProfile(
        id: 'soft-stack-test',
        version: 1,
        captureOnlySingleOpponentPawn: true,
      );
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: profile,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(4);

      final result = game.evaluatePawnMove(0);

      expect(result, isA<ValidMove>());
      expect((result as ValidMove).pathTiles, [4, 5, 6, 7]);
      expect(result.isCapture, isFalse);
    });

    test('Classic blockade prevents passing through two opponent pawns', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(4);

      final result = game.evaluatePawnMove(0);

      expect(result, isA<InvalidMove>());
      expect(
        (result as InvalidMove).reason,
        MoveInvalidReason.pathBlockedByBlockade,
      );
      expect(game.currentPlayer.pawnProgress[0], 3);
    });

    test('Classic cannot land on a protected opponent stack', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(2);

      expect(
        game.evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.landingOnProtectedStack,
        ),
      );
      expect(game.legalPawnIndices(), isEmpty);
    });

    test('a friendly pawn can reinforce an occupied cell', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [3, 5, -1, -1],
        },
      ).roll(2);

      final result = game.evaluatePawnMove(0);

      expect(result, isA<ValidMove>());
      expect((result as ValidMove).isCapture, isFalse);
    });

    test('a lone opponent on an unsafe cell is captured', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, -1, -1, -1],
        },
      ).roll(2);

      final result = game.evaluatePawnMove(0);

      expect(result, isA<ValidMove>());
      expect((result as ValidMove).isCapture, isTrue);
      expect(result.capturedPawnColor, PlayerColor.green);
      expect(result.capturedPawnIndex, 0);
    });

    test('a lone opponent on a safe cell is not captured', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [7, -1, -1, -1],
          PlayerColor.green: [47, -1, -1, -1],
        },
      ).roll(1);

      final result = game.evaluatePawnMove(0);

      expect(result, isA<ValidMove>());
      expect((result as ValidMove).isCapture, isFalse);
    });

    test('overshooting home returns a structured reason', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [55, -1, -1, -1],
        },
      ).roll(2);

      expect(
        game.evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.overshootsHome,
        ),
      );
    });

    test('yard pawn needs a six and a pending roll', () {
      final initial = LudoGame.initial();
      expect(
        initial.evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.noPendingRoll,
        ),
      );

      final rolledFive = initial.roll(5);
      expect(
        rolledFive.evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.pawnInYardNeedsSix,
        ),
      );
    });
  });
}
