import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

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

  bool isDiceAnimating = false;
  int diceRollId = 0;

  void restorePendingDiceRoll() {
    isDiceAnimating = true;
    diceRollId = 1;
  }

  void presentAcceptedRoll({required bool hasDiceResult}) {
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
    String? feedback,
  }) {
    pawn.begin(
      player: color,
      index: pawnIndex,
      start: startProgress,
      end: endProgress,
      moveFeedback: feedback,
    );
    movement.duration = _timing.pawnMovement(
      stepCount: stepCount,
      reduceMotion: reduceMotion,
    );
  }

  void startPawnMovement() {
    preview.stop();
    movement.forward(from: 0);
  }

  String? completePawnMovement() => pawn.complete();

  void stopPreview() {
    preview.stop();
  }

  /// Invalidates in-flight animation before the match session is replaced.
  void resetForNewMatch() {
    movement.stop();
    movement.value = 0;
    preview.stop();
    preview.value = 0;
    pawn.clear();
    isDiceAnimating = false;
    diceRollId = 0;
  }

  void dispose() {
    movement.dispose();
    preview.dispose();
  }
}
