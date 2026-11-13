import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';

/// Safe-square markers derived from the authoritative board geometry.
///
/// Start squares are already colour-coded in the approved artwork. Only the
/// four non-start safe cells receive a gold star. Decorative markers never
/// intercept pawn gestures or modify the game rules.
class MatchSafeStarLayer extends StatelessWidget {
  const MatchSafeStarLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final index in BoardGeometry.starTrackCells.toList()..sort())
            _starAt(index),
        ],
      ),
    );
  }

  Widget _starAt(int index) {
    final position = BoardGeometry.canvasPosition(
      BoardGeometry.trackPosition(index),
    );
    return Positioned(
      left: position.x - 13,
      top: position.y - 13,
      width: 26,
      height: 26,
      child: Center(
        child: Icon(
          Icons.star_rounded,
          key: Key('safe_star_$index'),
          color: const Color(0xE6FFD36B),
          size: 21,
          shadows: const [
            Shadow(color: Color(0xE6111017), blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
