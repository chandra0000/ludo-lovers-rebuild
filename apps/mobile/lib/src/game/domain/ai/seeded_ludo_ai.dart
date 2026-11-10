import 'dart:math';

import '../ludo_game.dart';

/// Deterministic, engine-constrained pawn selection for local AI seats.
///
/// The strategy never creates a move itself: it evaluates only pawn indexes
/// returned by [LudoGame.legalPawnIndices] and scores the resulting immutable
/// engine states.
class SeededLudoAi {
  const SeededLudoAi();

  int? choosePawn(LudoGame game, {required int seed}) {
    final legal = game.legalPawnIndices();
    if (legal.isEmpty) return null;

    final random = Random(seed);
    final scored = <({int pawn, int score, int tieBreak})>[];
    for (final pawnIndex in legal) {
      final next = game.movePawn(pawnIndex);
      final moved = next.currentPlayer.pawnProgress[pawnIndex];
      final previous = game.currentPlayer.pawnProgress[pawnIndex];
      var score = moved == 56 ? 10000 : moved * 10;
      if (previous == -1) score += 80;
      score += next.events.whereType<PawnCaptured>().length * 500;
      if (next.winner != null) score += 100000;
      scored.add((
        pawn: pawnIndex,
        score: score,
        tieBreak: random.nextInt(1 << 20),
      ));
    }
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.tieBreak.compareTo(b.tieBreak);
    });
    return scored.first.pawn;
  }
}
