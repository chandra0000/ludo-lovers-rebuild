import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Phase 2 capture and blockade rules', () {
    test('landing on an unsafe occupied cell captures the opponent', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[4, -1, -1, -1],
          PlayerColor.green: <int>[44, -1, -1, -1],
        },
      ).roll(1);
      final evaluation = game.evaluatePawnMove(0);
      expect(evaluation, isA<ValidMove>());
      expect((evaluation as ValidMove).isCapture, isTrue);
      final moved = game.movePawn(0);
      expect(moved.players[1].pawnProgress[0], -1);
      expect(moved.activePlayer, PlayerColor.orange);
      expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
    });

    test('safe cells prevent capture even with an opponent present', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[7, -1, -1, -1],
          PlayerColor.green: <int>[47, -1, -1, -1],
        },
      ).roll(1);
      final moved = game.movePawn(0);
      expect(moved.players[1].pawnProgress[0], 47);
      expect(moved.events.whereType<PawnCaptured>(), isEmpty);
      expect(moved.activePlayer, PlayerColor.green);
    });

    test('classic rules protect a stacked opponent landing cell', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[4, -1, -1, -1],
          PlayerColor.green: <int>[44, 44, -1, -1],
        },
      ).roll(1);
      expect(game.legalPawnIndices(), isEmpty);
      expect(game.awaitingPass, isTrue);
      expect(
        (game.evaluatePawnMove(0) as InvalidMove).reason,
        MoveInvalidReason.landingOnProtectedStack,
      );
    });

    test('classic hard blockade blocks intermediate traversal', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[1, -1, -1, -1],
          PlayerColor.green: <int>[42, 42, -1, -1],
        },
      ).roll(4);
      expect(
        (game.evaluatePawnMove(0) as InvalidMove).reason,
        MoveInvalidReason.pathBlockedByBlockade,
      );
      expect(game.awaitingPass, isTrue);
    });

    test('current profile preserves legacy stacked capture behavior', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: <PlayerColor, List<int>>{
          PlayerColor.orange: <int>[4, -1, -1, -1],
          PlayerColor.green: <int>[44, 44, -1, -1],
        },
      ).roll(1).movePawn(0);
      expect(game.players[1].pawnProgress.take(2), <int>[-1, -1]);
      expect(game.events.whereType<PawnCaptured>(), hasLength(2));
    });
  });
}
