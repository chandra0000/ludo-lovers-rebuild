import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  const ai = SeededLudoAi();

  test('returns null when the engine exposes no legal pawn action', () {
    final game = LudoGame.initial().roll(2);
    expect(ai.choosePawn(game, seed: 7), isNull);
  });

  test('chooses only a legal pawn and repeats the same choice for a seed', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, 10, -1, -1],
      },
    ).roll(2);
    final first = ai.choosePawn(game, seed: 42);
    final second = ai.choosePawn(game, seed: 42);
    expect(first, isNotNull);
    expect(game.legalPawnIndices(), contains(first));
    expect(second, first);
  });

  test('prioritizes a capture over a non-capturing legal move', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, 10, -1, -1],
        PlayerColor.green: [44, -1, -1, -1],
      },
    ).roll(1);
    expect(ai.choosePawn(game, seed: 1), 0);
  });

  test('prioritizes a winning move when one is available', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [55, 12, 20, 30],
      },
    ).roll(1);
    expect(ai.choosePawn(game, seed: 9), 0);
  });
  test('four seeded AI seats complete a deterministic full match', () {
    const seed = 731;
    final random = Random(seed);
    var game = LudoGame.initial();
    var transitions = 0;

    while (game.winner == null && transitions < 100000) {
      if (game.diceValue == null) {
        game = game.roll(random.nextInt(6) + 1);
        transitions++;
      }
      final legal = game.legalPawnIndices();
      if (legal.isEmpty) {
        game = game.passTurn();
      } else {
        final selected = ai.choosePawn(
          game,
          seed: seed ^ game.stateVersion,
        );
        expect(legal, contains(selected));
        game = game.movePawn(selected!);
      }
      transitions++;
      expect(
        game.players.every(
          (player) => player.pawnProgress.every(
            (progress) => progress >= -1 && progress <= 56,
          ),
        ),
        isTrue,
      );
    }

    expect(game.winner, isNotNull);
    expect(transitions, lessThan(100000));
    expect(game.currentPlayer.hasWon, isTrue);
  });

}
