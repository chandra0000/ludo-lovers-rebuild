import 'package:flutter/material.dart';

import '../../game/presentation/luxury_dice.dart';

/// Interactive dice overlay, independent from the decorative board image.
///
/// Positions are expressed in the existing 576 x 1024 design canvas so that
/// the authoritative board geometry remains unchanged during this refactor.
class MatchDiceLayer extends StatelessWidget {
  const MatchDiceLayer({
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
    return Positioned(
      left: 243,
      top: 795,
      width: 90,
      height: 90,
      child: KeyedSubtree(
        key: const Key('roll_dice'),
        child: LuxuryDiceButton(
          key: const Key('animated_dice'),
          targetValue: targetValue,
          rollId: rollId,
          canRoll: canRoll,
          isWaitingForRoll: isWaitingForRoll,
          onRollRequested: onRollRequested,
          onAnimationComplete: onAnimationComplete,
        ),
      ),
    );
  }
}
