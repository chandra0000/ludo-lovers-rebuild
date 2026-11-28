import 'package:flutter/animation.dart';

import '../../game/domain/player_color.dart';
import 'match_animation_timing.dart';
import 'match_movement_presentation.dart';

/// Owns transient dice, pawn and destination-preview animation state.
///
/// This is a presentation controller only. MatchSession remains the sole
/// authority for dice values, valid pawn moves and game outcomes.
class MatchAnimationLifecycle {
  MatchAnimationLifecycle({
    required TickerProvider vsync,
    required VoidCallback onMovementTick,
    required AnimationStatusListener onMovementStatus,
  })  : movement = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 160),
        ),
        preview = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 1200),
        ) {
    movement.addListener(onMovementTick);
    movement.addStatusListener(onMovementStatus);
  }

  final AnimationController movement;
  final AnimationController preview;
  final MatchMovementPresentation pawn = MatchMovementPresentation();
  final MatchAnimationTiming _timing = const MatchAnimationTiming();

  static const impactMs = 70;
  static const retreatStepMs = 48;

  double retreatFraction(int startProgress) =>
      ((elapsedMs - approachMs - impactMs) /
              (retreatStepMs * (startProgress + 1)))
          .clamp(0.0, 1.0)
          .toDouble();

  Map<(PlayerColor, int), int> captures = const {};
  int approachMs = 0;
  double get elapsedMs => movement.value * movement.duration!.inMilliseconds;
  double get approach =>
      approachMs == 0 ? 1 : (elapsedMs / approachMs).clamp(0.0, 1.0).toDouble();

  bool isDiceAnimating = false;
  int diceRollId = 0;
  int? presentedDiceValue;

  void restorePendingDiceRoll() {
    isDiceAnimating = true;
    diceRollId = 1;
  }

  void presentAcceptedRoll({required bool hasDiceResult, int? value}) {
    presentedDiceValue = value;
    isDiceAnimating = hasDiceResult;
    if (hasDiceResult) diceRollId++;
  }

  /// Resolves an interrupted/restored pending roll without replaying the die.
  void resumePendingDiceResult() {
    isDiceAnimating = true;
  }

  void completeDiceRoll() {
    isDiceAnimating = false;
  }

  void configurePawnMovement({
    required PlayerColor color,
    required int pawnIndex,
    required int startProgress,
    required int endProgress,
    required int stepCount,
    required bool reduceMotion,
    Map<(PlayerColor, int), int> retreats = const {},
    String? feedback,
  }) {
    pawn.begin(
      player: color,
      index: pawnIndex,
      start: startProgress,
      end: endProgress,
      moveFeedback: feedback,
    );
    captures = retreats;
    approachMs = _timing
        .pawnMovement(
          stepCount: stepCount,
          reduceMotion: reduceMotion,
        )
        .inMilliseconds;
    var longest = 0;
    for (final progress in retreats.values) {
      if (progress + 1 > longest) longest = progress + 1;
    }
    movement.duration = Duration(
      milliseconds: reduceMotion || longest == 0
          ? approachMs
          : approachMs + impactMs + longest * retreatStepMs,
    );
  }

  void startPawnMovement() {
    preview.stop();
    movement.forward(from: 0);
  }

  String? completePawnMovement() {
    captures = const {};
    return pawn.complete();
  }

  void stopPreview() {
    preview.stop();
  }

  /// Invalidates in-flight animation before the match session is replaced.
  void resetForNewMatch() {
    movement.stop();
    movement.value = 0;
    preview.stop();
    preview.value = 0;
    captures = const {};
    pawn.clear();
    isDiceAnimating = false;
    diceRollId = 0;
    presentedDiceValue = null;
  }

  void dispose() {
    movement.dispose();
    preview.dispose();
  }
}
