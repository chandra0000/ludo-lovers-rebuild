import 'dart:math';

import '../board_geometry.dart';
import '../ludo_game.dart';

/// Deterministic, engine-constrained pawn selection for local AI seats.
///
/// The strategy evaluates only legal pawn indexes and scores immutable
/// snapshots produced by the authoritative game engine. It never implements
/// movement, capture, or winning rules itself.
class SeededLudoAi {
  const SeededLudoAi();

  int? choosePawn(LudoGame game, {required int seed}) {
    final legal = game.legalPawnIndices();
    if (legal.isEmpty) return null;

    final random = Random(seed);
    final scored = <({int pawn, int score, int tieBreak})>[];

    for (final pawnIndex in legal) {
      // movePawn returns a new immutable snapshot. No command ID is supplied,
      // so evaluating candidates cannot consume a live command identifier.
      final next = game.movePawn(pawnIndex);
      final previousProgress = game.currentPlayer.pawnProgress[pawnIndex];
      final movedProgress = next.players
          .firstWhere((player) => player.color == game.activePlayer)
          .pawnProgress[pawnIndex];

      var score = 0;

      // Winning the match must dominate every tactical consideration.
      if (next.winner != null && game.winner == null) {
        score += 100000;
      }

      // Completing an individual pawn is the next strongest objective.
      if (movedProgress == finishProgress) {
        score += 10000;
      }

      // Events belong to this transition, not the whole match history.
      final captureCount = next.events.whereType<PawnCaptured>().length;
      score += captureCount * 800;

      // Prefer releasing a pawn from the yard when no stronger move exists.
      if (previousProgress == -1 && movedProgress == 0) {
        score += 350;
      }

      // Home-lane progress is protected from shared-track captures.
      if (previousProgress < playerTrackLength &&
          movedProgress >= playerTrackLength &&
          movedProgress < finishProgress) {
        score += 300;
      }

      // Reward landing on a safe shared-track cell.
      if (movedProgress >= 0 && movedProgress < playerTrackLength) {
        final trackIndex = BoardGeometry.physicalTrackCell(
          game.activePlayer,
          movedProgress,
        );
        if (BoardGeometry.safeTrackCells.contains(trackIndex)) {
          score += 150;
        }
      }

      // A modest progress incentive breaks ties between similarly safe moves.
      score += movedProgress * 8;

      // Move a vulnerable pawn when an opponent is close behind it.
      if (previousProgress >= 0 &&
          previousProgress < playerTrackLength) {
        final previousTrackCell = BoardGeometry.physicalTrackCell(
          game.activePlayer,
          previousProgress,
        );
        if (!BoardGeometry.safeTrackCells.contains(previousTrackCell) &&
            _isThreatened(game, previousTrackCell)) {
          score += 200;
        }
      }

      scored.add((
        pawn: pawnIndex,
        score: score,
        tieBreak: random.nextInt(1 << 20),
      ),);
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.tieBreak.compareTo(b.tieBreak);
    });

    return scored.first.pawn;
  }

  /// Returns true when an opponent is one to six shared-track steps behind
  /// [trackCell], assuming the standard forward movement direction.
  bool _isThreatened(LudoGame game, int trackCell) {
    for (final opponent in game.players) {
      if (opponent.color == game.activePlayer) continue;

      for (final progress in opponent.pawnProgress) {
        if (progress < 0 || progress >= playerTrackLength) continue;

        final opponentTrackCell =
            BoardGeometry.physicalTrackCell(opponent.color, progress);
        final distance =
            (trackCell - opponentTrackCell + BoardGeometry.trackLength) %
                BoardGeometry.trackLength;
        if (distance >= 1 && distance <= 6) {
          return true;
        }
      }
    }
    return false;
  }
}
