import 'package:flutter/material.dart';

import 'match_dice_layer.dart';

/// Dice presentation boundary. The session owns all roll validation.
class DiceControlDock extends StatelessWidget {
  const DiceControlDock({
    super.key,
    required this.targetValue,
    required this.rollId,
    required this.canRoll,
    required this.isWaitingForRoll,
    required this.onRollRequested,
    required this.onAnimationComplete,
  });

  final int? targetValue;
  final int rollId;
  final bool canRoll;
  final bool isWaitingForRoll;
  final VoidCallback onRollRequested;
  final VoidCallback onAnimationComplete;

  @override
  Widget build(BuildContext context) {
    return MatchDiceLayer(
      targetValue: targetValue,
      rollId: rollId,
      canRoll: canRoll,
      isWaitingForRoll: isWaitingForRoll,
      onRollRequested: onRollRequested,
      onAnimationComplete: onAnimationComplete,
    );
  }
}
