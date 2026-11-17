import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/glassy_pawn.dart';
import '../../game/presentation/player_color_theme.dart';
import '../../game/presentation/shake_feedback_wrapper.dart';
import 'game/systems/pawn_animator.dart';
import 'game/systems/pawn_layout_solver.dart';
import 'match_animation_lifecycle.dart';
import 'match_move_presentation_plan.dart';

/// Renders engine-owned pawn state. Callbacks request actions; this layer never
/// applies commands, schedules turns, owns tickers or changes game rules.
class MatchPawnLayer extends StatelessWidget {
  const MatchPawnLayer({
    super.key,
    required this.game,
    required this.animations,
    required this.canvasScale,
    required this.isTurnResolutionPending,
    required this.aiPlayers,
    required this.shakeKeys,
    required this.reduceMotion,
    required this.lastLandingPlan,
    required this.landingSequence,
    required this.onMove,
    required this.onStackTap,
    required this.onInvalidMove,
  });

  final LudoGame game;
  final MatchAnimationLifecycle animations;
  final double canvasScale;
  final bool isTurnResolutionPending;
  final Set<PlayerColor> aiPlayers;
  final Map<String, GlobalKey<ShakeFeedbackWrapperState>> shakeKeys;
  final bool reduceMotion;
  final MatchMovePresentationPlan? lastLandingPlan;
  final int landingSequence;
  final ValueChanged<int> onMove;
  final ValueChanged<List<int>> onStackTap;
  final ValueChanged<int> onInvalidMove;

  @override
  Widget build(BuildContext context) => Stack(
        children: _buildPawnsWithClusters(canvasScale),
      );

  NormalizedBoardPoint _pawnPosition(
    PlayerColor color,
    int pawnIndex,
  ) {
    final player = game.players.firstWhere((item) => item.color == color);
    return PawnAnimator.position(
      color: color,
      pawnIndex: pawnIndex,
      progress: player.pawnProgress[pawnIndex],
      isMoving: animations.pawn.color == color &&
          animations.pawn.pawnIndex == pawnIndex,
      startProgress: animations.pawn.startProgress,
      endProgress: animations.pawn.endProgress,
      animationValue: animations.movement.value,
    );
  }

  List<Widget> _buildPawnsWithClusters(double canvasScale) {
    // Index players once per frame instead of searching for each pawn.
    final playersByColor = {
      for (final player in game.players) player.color: player,
    };
    final clusters = <int, List<({PlayerColor color, int pawnIndex})>>{};
    for (final color in PlayerColor.turnOrder) {
      final player = playersByColor[color]!;
      for (var pawnIndex = 0;
          pawnIndex < player.pawnProgress.length;
          pawnIndex++) {
        final point = _pawnPosition(color, pawnIndex);
        final key = PawnLayoutSolver.clusterKey(point);
        clusters.putIfAbsent(key, () => []).add(
          (color: color, pawnIndex: pawnIndex),
        );
      }
    }
    for (final occupants in clusters.values) {
      occupants.sort((a, b) {
        final colorOrder = PlayerColor.turnOrder.indexOf(a.color).compareTo(
              PlayerColor.turnOrder.indexOf(b.color),
            );
        return colorOrder != 0
            ? colorOrder
            : a.pawnIndex.compareTo(b.pawnIndex);
      });
    }
    final legalIndices = game.legalPawnIndices().toSet();
    return [
      for (final color in PlayerColor.turnOrder)
        for (var pawnIndex = 0; pawnIndex < 4; pawnIndex++)
          _buildPawn(
            color,
            pawnIndex,
            playersByColor[color]!,
            clusters,
            legalIndices,
            canvasScale,
          ),
    ];
  }

  Widget _buildPawn(
    PlayerColor color,
    int pawnIndex,
    LudoPlayer player,
    Map<int, List<({PlayerColor color, int pawnIndex})>> clusters,
    Set<int> legalIndices,
    double canvasScale,
  ) {
    final progress = player.pawnProgress[pawnIndex];
    final normalized = _pawnPosition(color, pawnIndex);
    final canvasPoint = BoardGeometry.canvasPosition(normalized);
    final occupants = clusters[PawnLayoutSolver.clusterKey(normalized)] ??
        [
          (color: color, pawnIndex: pawnIndex),
        ];
    final stackIndex = occupants.indexWhere(
      (item) => item.color == color && item.pawnIndex == pawnIndex,
    );
    final stacked = occupants.length > 1;
    final slot = PawnLayoutSolver.stackOffset(stackIndex, occupants.length);
    final visualOffset = Offset(slot.x, slot.y);
    final size = stacked ? 16.0 : (progress == -1 ? 30.0 : 27.0);
    final isHumanTurn =
        !aiPlayers.contains(color) && color == game.activePlayer;
    final canMove = !animations.isDiceAnimating &&
        !animations.movement.isAnimating &&
        !isTurnResolutionPending &&
        isHumanTurn &&
        legalIndices.contains(pawnIndex);
    final canExplainInvalidMove = !animations.isDiceAnimating &&
        !animations.movement.isAnimating &&
        !isTurnResolutionPending &&
        isHumanTurn &&
        game.diceValue != null &&
        !legalIndices.contains(pawnIndex);
    final movableStackIndices = occupants
        .where(
          (item) =>
              item.color == game.activePlayer &&
              legalIndices.contains(item.pawnIndex),
        )
        .map((item) => item.pawnIndex)
        .toList(growable: false);
    final stackTapIndex = occupants.indexWhere(
      (item) =>
          item.color == game.activePlayer &&
          legalIndices.contains(item.pawnIndex),
    );
    final isStackTapTarget = stacked && stackIndex == stackTapIndex;
    final isCurrentPlayer = color == game.activePlayer;
    final tapPosition = stacked
        ? Offset(canvasPoint.x, canvasPoint.y)
        : Offset(canvasPoint.x, canvasPoint.y) + visualOffset;

    // The canvas is scaled to fit the phone. Expand the design-space hitbox
    // inversely so its transformed physical bounds never fall below 48×48 dp.
    final hitTargetWidth = math.max(48.0, 48.0 / canvasScale);
    final hitTargetHeight = math.max(48.0, 48.0 / canvasScale);
    final shakeKey = shakeKeys.putIfAbsent(
      '${color.name}-$pawnIndex',
      GlobalKey<ShakeFeedbackWrapperState>.new,
    );
    return Positioned(
      left: tapPosition.dx - hitTargetWidth / 2,
      top: tapPosition.dy - hitTargetHeight / 2,
      width: hitTargetWidth,
      height: hitTargetHeight,
      child: IgnorePointer(
        // Inactive/non-legal pawns must not cover a legal pawn's enlarged
        // touch target when adjacent cells overlap on compact screens.
        ignoring:
            stacked ? !isStackTapTarget : !canMove && !canExplainInvalidMove,
        child: Semantics(
          button: stacked ? isStackTapTarget : canMove || canExplainInvalidMove,
          label: stacked
              ? 'Choose a movable pawn from this shared cell'
              : '${color.name} pawn ${pawnIndex + 1}',
          value: progress == -1
              ? 'In yard'
              : progress == 56
                  ? 'Home'
                  : 'Progress $progress of 56',
          hint: stacked
              ? 'Double tap to choose which movable pawn to move.'
              : canMove
                  ? 'Double tap to move this pawn.'
                  : canExplainInvalidMove
                      ? 'Double tap to hear why this pawn cannot move.'
                      : aiPlayers.contains(color)
                          ? 'Controlled by the AI opponent.'
                          : 'Not movable on this turn.',
          child: GestureDetector(
            key: Key('pawn_${color.name}_$pawnIndex'),
            behavior: HitTestBehavior.opaque,
            onTap: stacked
                ? (isStackTapTarget
                    ? () => onStackTap(movableStackIndices)
                    : null)
                : canMove
                    ? () => onMove(pawnIndex)
                    : canExplainInvalidMove
                        ? () => onInvalidMove(pawnIndex)
                        : null,
            child: Center(
              child: Transform.translate(
                offset: visualOffset,
                child: ShakeFeedbackWrapper(
                  key: shakeKey,
                  child: AnimatedScale(
                    scale: canMove ? 1.12 : 1,
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: Transform.rotate(
                      angle: animations.pawn.color == color &&
                              animations.pawn.pawnIndex == pawnIndex
                          ? math.sin(animations.movement.value * math.pi * 2) *
                              0.08
                          : 0,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'landing-${color.name}-$pawnIndex-${lastLandingPlan?.player == color && lastLandingPlan?.pawnIndex == pawnIndex ? landingSequence : 0}',
                        ),
                        tween: Tween(
                          begin: lastLandingPlan?.player == color &&
                                  lastLandingPlan?.pawnIndex == pawnIndex &&
                                  !reduceMotion
                              ? 1.12
                              : 1.0,
                          end: 1.0,
                        ),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: GlassyPawn(
                          color: color.color,
                          size: size,
                          isCurrentPlayer: isCurrentPlayer,
                          isMovable: canMove,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
