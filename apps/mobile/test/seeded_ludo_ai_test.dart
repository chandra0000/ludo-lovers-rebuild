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
    var turns = 0;

    while (game.winner == null && transitions < 5000) {
      if (game.diceValue == null) {
        game = game.roll(
          random.nextInt(6) + 1,
          expectedStateVersion: game.stateVersion,
          commandId: 'ai-$seed-$transitions-roll',
        );
        transitions++;
        turns++;
      }
      final legal = game.legalPawnIndices();
      if (legal.isEmpty) {
        game = game.passTurn(
          expectedStateVersion: game.stateVersion,
          commandId: 'ai-$seed-$transitions-pass',
        );
      } else {
        final selected = ai.choosePawn(
          game,
          seed: seed ^ game.stateVersion,
        );
        expect(legal, contains(selected));
        game = game.movePawn(
          selected!,
          expectedStateVersion: game.stateVersion,
          commandId: 'ai-$seed-$transitions-move',
        );
      }
      transitions++;
      expect(game.stateVersion, transitions);
      expect(game.appliedCommandIds.length, transitions);
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
    expect(turns, greaterThan(100));
    expect(transitions, lessThan(5000));
    expect(game.currentPlayer.hasWon, isTrue);
  });


  test('prefers a safe shared-track landing over raw progress', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [7, 10, -1, -1],
      },
    ).roll(1);

    // Orange progress 7 lands on safe physical track cell 8.
    expect(ai.choosePawn(game, seed: 12), 0);
  });

  test('prefers entering the protected home lane', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [50, 20, -1, -1],
      },
    ).roll(1);

    expect(ai.choosePawn(game, seed: 13), 0);
  });

  test('moves a vulnerable pawn when an opponent is close behind', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [10, 30, -1, -1],
        // Green progress 43 maps to shared-track cell 4, six spaces behind
        // Orange progress 10.
        PlayerColor.green: [43, -1, -1, -1],
      },
    ).roll(1);

    expect(ai.choosePawn(game, seed: 14), 0);
  });

  test('avoids moving a pawn onto an unsafe cell within an opponent roll', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        // Pawn 0 would move from Orange progress 21 to 22. Green progress 4
        // is five shared-track cells behind that unsafe landing position.
        PlayerColor.orange: [21, 10, -1, -1],
        PlayerColor.green: [4, -1, -1, -1],
      },
    ).roll(1);

    // Pawn 1 makes less raw progress but avoids the immediate capture threat.
    expect(ai.choosePawn(game, seed: 16), 1);
  });

  test('candidate evaluation does not mutate the supplied game snapshot', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, 10, -1, -1],
        PlayerColor.green: [44, -1, -1, -1],
      },
    ).roll(1);
    final originalVersion = game.stateVersion;
    final originalEvents = List<LudoGameEvent>.of(game.events);
    final originalCommandIds = Set<String>.of(game.appliedCommandIds);
    final originalProgress = List<int>.of(game.currentPlayer.pawnProgress);

    expect(ai.choosePawn(game, seed: 15), 0);
    expect(game.stateVersion, originalVersion);
    expect(game.events, originalEvents);
    expect(game.appliedCommandIds, originalCommandIds);
    expect(game.currentPlayer.pawnProgress, originalProgress);
  });

  test('all difficulty levels choose only engine-approved legal pawns', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      ruleProfile: LudoRuleProfile.classicV1,
      pawnProgress: {
        PlayerColor.orange: [7, 10, 22, -1],
        PlayerColor.green: [44, -1, -1, -1],
      },
    ).roll(2);
    final legal = game.legalPawnIndices();

    for (final difficulty in LudoAiDifficulty.values) {
      final first = ai.choosePawn(
        game,
        seed: 2026,
        difficulty: difficulty,
      );
      final repeated = ai.choosePawn(
        game,
        seed: 2026,
        difficulty: difficulty,
      );
      expect(legal, contains(first), reason: '${difficulty.name} legality');
      expect(repeated, first, reason: '${difficulty.name} seeded repeatability');
    }
  });

  test('easy difficulty remains deterministic while selecting a legal move', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, 10, -1, -1],
      },
    ).roll(1);
    final selected = ai.choosePawn(
      game,
      seed: 73,
      difficulty: LudoAiDifficulty.easy,
    );

    expect(game.legalPawnIndices(), contains(selected));
    expect(
      ai.choosePawn(
        game,
        seed: 73,
        difficulty: LudoAiDifficulty.easy,
      ),
      selected,
    );
  });

  test('hard difficulty avoids an immediately threatened unsafe landing', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [21, 10, -1, -1],
        PlayerColor.green: [4, -1, -1, -1],
      },
    ).roll(1);

    expect(
      ai.choosePawn(
        game,
        seed: 16,
        difficulty: LudoAiDifficulty.hard,
      ),
      1,
    );
  });

  test('seeded AI follows the supplied Classic profile blockade legality', () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      ruleProfile: LudoRuleProfile.classicV1,
      pawnProgress: {
        PlayerColor.orange: [3, 10, -1, -1],
        PlayerColor.green: [44, 44, -1, -1],
      },
    ).roll(3);

    // The first pawn is blocked mid-route; the second is the only legal move.
    expect(game.legalPawnIndices(), [1]);
    final selected = ai.choosePawn(game, seed: 2026);
    expect(selected, 1);

    final moved = game.movePawn(selected!);
    expect(moved.ruleProfile, LudoRuleProfile.classicV1);
    final orangeAfterMove = moved.players.firstWhere(
      (player) => player.color == PlayerColor.orange,
    );
    expect(orangeAfterMove.pawnProgress[1], 13);
  });

}
