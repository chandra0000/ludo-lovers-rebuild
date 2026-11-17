import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';

/// Read-only accessibility anchors for authoritative safe cells.
///
/// The approved board image already paints the four non-entry gold stars and
/// four colored entries. Painting icons here would duplicate that artwork.
/// Rules and anchors come from geometry; artwork colors never determine safety.
class MatchSafeStarLayer extends StatelessWidget {
  const MatchSafeStarLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final index in BoardGeometry.safeTrackCells.toList()..sort())
            _anchorAt(index),
        ],
      ),
    );
  }

  Widget _anchorAt(int index) {
    final position = BoardGeometry.canvasPosition(
      BoardGeometry.trackPosition(index),
    );
    return Positioned(
      left: position.x - 13,
      top: position.y - 13,
      width: 26,
      height: 26,
      child: Semantics(
        key: Key('safe_cell_$index'),
        label: 'Safe cell ${index + 1}',
        readOnly: true,
        child: const SizedBox.expand(),
      ),
    );
  }
}
