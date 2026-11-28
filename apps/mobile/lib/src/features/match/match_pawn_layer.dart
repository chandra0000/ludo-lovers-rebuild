import '../../../features/game/presentation/widgets/legal_pawn_emphasis.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  final ValueChanged<int> onInvalidMove;

  @override
  Widget build(BuildContext context) => _PawnTargets(
        children: _buildPawnsWithClusters(canvasScale),
      );

  NormalizedBoardPoint _pawnPosition(
    PlayerColor color,
    int pawnIndex,
  ) {
    final player = game.players.firstWhere((item) => item.color == color);
    final captured = animations.captures[(color, pawnIndex)];
    if (captured != null) {
      return PawnAnimator.position(
        color: color,
        pawnIndex: pawnIndex,
        progress: -1,
        isMoving: true,
        startProgress: -1,
        endProgress: captured,
        animationValue: 1 - animations.retreatFraction(captured),
      );
    }
    return PawnAnimator.position(
      color: color,
      pawnIndex: pawnIndex,
      progress: player.pawnProgress[pawnIndex],
      isMoving: animations.pawn.color == color &&
          animations.pawn.pawnIndex == pawnIndex,
      startProgress: animations.pawn.startProgress,
      endProgress: animations.pawn.endProgress,
      animationValue: animations.approach,
    );
  }

  List<Widget> _buildPawnsWithClusters(double canvasScale) {
    // Index players once per frame instead of searching for each pawn.
    final playersByColor = {
      for (final player in game.players) player.color: player,
    };
    final clusters = <int, List<({PlayerColor color, int pawnIndex})>>{};
    for (final color in game.configuration.activePlayers) {
      final player = playersByColor[color]!;
      for (var pawnIndex = 0;
          pawnIndex < player.pawnProgress.length;
          pawnIndex++) {
        if (_isRestingHome(player, pawnIndex)) continue;
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
      for (final color in game.configuration.activePlayers)
        for (var pawnIndex = 0; pawnIndex < 4; pawnIndex++)
          if (!_isRestingHome(playersByColor[color]!, pawnIndex))
            _buildPawn(
              color,
              pawnIndex,
              playersByColor[color]!,
              clusters,
              legalIndices,
              canvasScale,
            ),
      for (final player in game.players) ..._homeTokens(player),
    ];
  }

  bool _isRestingHome(LudoPlayer player, int pawn) =>
      player.pawnProgress[pawn] == finishProgress &&
      !animations.pawn.matches(player.color, pawn);

  Iterable<Widget> _homeTokens(LudoPlayer player) sync* {
    final finished = [
      for (var pawn = 0; pawn < player.pawnProgress.length; pawn++)
        if (_isRestingHome(player, pawn)) pawn,
    ];
    if (finished.isEmpty) return;
    final center = BoardGeometry.canvasPosition(BoardGeometry.finishPosition);
    final lane = BoardGeometry.canvasPosition(
      BoardGeometry.normalizedPosition(player.color, finishProgress - 1, 0),
    );
    final direction = Offset(lane.x - center.x, lane.y - center.y);
    final axis = direction / direction.distance;
    final across = Offset(-axis.dy, axis.dx);
    for (var index = 0; index < finished.length; index++) {
      final offset =
          axis * (index < 2 ? 18 : 28) + across * (index.isEven ? -4.5 : 4.5);
      yield Positioned(
        key: Key('home_token_${player.color.name}_${finished[index]}'),
        left: center.x + offset.dx - 4,
        top: center.y + offset.dy - 4,
        width: 8,
        height: 8,
        child: IgnorePointer(
          child: Semantics(
            label:
                '${player.color.name} · ${finished.length}/${game.configuration.finishTarget} home',
            hidden: index != 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: player.color.color,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE3A0)),
              ),
            ),
          ),
        ),
      );
    }
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
    final size = stacked
        ? (occupants.length <= 4 ? 27.0 * .75 : 16.0)
        : (progress == -1 ? 30.0 : 27.0);
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
    final moving =
        animations.pawn.matches(color, pawnIndex) && animations.approach < 1;
    final steps = animations.pawn.endProgress - animations.pawn.startProgress;
    final hop =
        moving ? math.sin(math.pi * ((animations.approach * steps) % 1)) : 0.0;
    final stretch = 1 + .08 * hop;
    final isCurrentPlayer = color == game.activePlayer;
    final friendly = occupants
        .where((p) => p.color == color && legalIndices.contains(p.pawnIndex))
        .toList();
    final fanIndex = friendly.indexWhere((p) => p.pawnIndex == pawnIndex);
    final fan = canMove && progress >= 0 && friendly.length > 1;
    final offset = fan
        ? Offset((fanIndex - (friendly.length - 1) / 2) * 16 / canvasScale, 0)
        : visualOffset;
    final tapPosition = Offset(
          fan
              ? (canvasPoint.x + offset.dx).clamp(
                  24 / canvasScale,
                  BoardGeometry.canvasWidth - 24 / canvasScale,
                )
              : canvasPoint.x + offset.dx,
          canvasPoint.y + offset.dy,
        ) +
        Offset(0, canMove && legalIndices.length > 1 && !reduceMotion ? -3 : 0);

    // The canvas is scaled to fit the phone. Expand the design-space hitbox
    // inversely so its transformed physical bounds never fall below 48×48 dp.
    final target = canMove && legalIndices.length > 1 ? 57.6 : 48.0;
    final hitTargetWidth = math.max(target, target / canvasScale);
    final hitTargetHeight = hitTargetWidth;
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
        ignoring: !canMove && !canExplainInvalidMove,
        child: Semantics(
          button: canMove || canExplainInvalidMove,
          label: '${color.name} pawn ${pawnIndex + 1}',
          value: progress == -1
              ? 'In yard'
              : progress == 56
                  ? 'Home'
                  : 'Progress $progress of 56',
          hint: canMove
              ? 'Double tap to move this pawn.'
              : canExplainInvalidMove
                  ? 'Double tap to hear why this pawn cannot move.'
                  : 'Pawn unavailable.',
          child: GestureDetector(
            key: Key('pawn_${color.name}_$pawnIndex'),
            behavior: HitTestBehavior.opaque,
            onTap: canMove
                ? () => onMove(pawnIndex)
                : canExplainInvalidMove
                    ? () => onInvalidMove(pawnIndex)
                    : null,
            child: Center(
              child: Transform.translate(
                offset: Offset.zero,
                child: ShakeFeedbackWrapper(
                  key: shakeKey,
                  child: AnimatedScale(
                    scale: 1,
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
                          begin: (lastLandingPlan?.player == color &&
                                      lastLandingPlan?.pawnIndex ==
                                          pawnIndex) &&
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
                        child: LegalPawnEmphasis(
                          canvasScale: canvasScale,
                          movable: canMove && legalIndices.length > 1,
                          reducedMotion: reduceMotion,
                          badge: stacked ? pawnIndex + 1 : null,
                          child: Transform.scale(
                            scaleX: 1 / math.sqrt(stretch),
                            scaleY: stretch,
                            alignment: Alignment.bottomCenter,
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
        ),
      ),
    );
  }
}

/// Overlapping accessible targets resolve to the nearest interactive pawn.
class _PawnTargets extends Stack {
  const _PawnTargets({required super.children});

  @override
  RenderStack createRenderObject(BuildContext context) => _PawnTargetStack(
        textDirection: Directionality.of(context),
      );
}

class _PawnTargetStack extends RenderStack {
  _PawnTargetStack({required super.textDirection});

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final candidates = <({RenderBox child, Offset origin, double distance})>[];
    for (var child = lastChild; child != null; child = childBefore(child)) {
      final origin = (child.parentData! as StackParentData).offset;
      final local = position - origin;
      if (child.size.contains(local)) {
        final distance =
            (local - child.size.center(Offset.zero)).distanceSquared;
        candidates.add((child: child, origin: origin, distance: distance));
      }
    }
    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    for (final target in candidates) {
      if (result.addWithPaintOffset(
        offset: target.origin,
        position: position,
        hitTest: (result, local) =>
            target.child.hitTest(result, position: local),
      )) {
        return true;
      }
    }
    return false;
  }
}
