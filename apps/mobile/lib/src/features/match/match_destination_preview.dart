import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/presentation/destination_preview_painter.dart';
import '../../game/presentation/player_color_theme.dart';

/// Read-only projection of the engine's move evaluation onto canonical anchors.
class MatchDestinationPreview extends StatelessWidget {
  const MatchDestinationPreview({
    super.key,
    required this.game,
    required this.selectedPawnIndex,
    required this.animation,
  });
  final LudoGame game;
  final int selectedPawnIndex;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final pawnIndex = selectedPawnIndex;
    final roll = game.diceValue!;
    final progress = game.currentPlayer.pawnProgress[pawnIndex];
    final target = progress == -1 ? 0 : progress + roll;
    final point = BoardGeometry.canvasPosition(
      BoardGeometry.normalizedPosition(game.activePlayer, target, pawnIndex),
    );
    // Derive the visual arrows from the same authoritative progress anchors
    // as pawn movement, including turns and home-lane transitions.
    final routePoints = <Offset>[];
    for (var step = progress; step <= target; step++) {
      final anchor = BoardGeometry.canvasPosition(
        BoardGeometry.normalizedPosition(
          game.activePlayer,
          step,
          pawnIndex,
        ),
      );
      routePoints.add(Offset(anchor.x, anchor.y));
    }
    final evaluation = game.evaluatePawnMove(pawnIndex);
    var type = DestinationPreviewType.standard;
    if (evaluation is ValidMove && evaluation.isCapture) {
      type = DestinationPreviewType.capture;
    } else if (target < BoardGeometry.playerTrackLength) {
      final cell = BoardGeometry.physicalTrackCell(game.activePlayer, target);
      final hasOpponent = game.players.any(
        (player) =>
            player.color != game.activePlayer &&
            player.pawnProgress.any(
              (opponentProgress) =>
                  opponentProgress >= 0 &&
                  opponentProgress < BoardGeometry.playerTrackLength &&
                  BoardGeometry.physicalTrackCell(
                        player.color,
                        opponentProgress,
                      ) ==
                      cell,
            ),
      );
      if (hasOpponent && BoardGeometry.safeTrackCells.contains(cell)) {
        type = DestinationPreviewType.safeCoexist;
      }
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => CustomPaint(
            key: const Key('destination_preview'),
            painter: DestinationPreviewPainter(
              targetCenter: Offset(point.x, point.y),
              routePoints: routePoints,
              cellSize: 36,
              playerColor: game.activePlayer.color,
              previewType: type,
              animationProgress:
                  MediaQuery.maybeOf(context)?.disableAnimations == true
                      ? 0
                      : animation.value,
            ),
          ),
        ),
      ),
    );
  }
}
