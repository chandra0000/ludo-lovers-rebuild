import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import '../../game/domain/player_color.dart';

/// Assert-only switch: release and profile builds always return false.
bool get debugBoardOverlayEnabled {
  var enabled = false;
  assert(() {
    enabled = true;
    return true;
  }());
  return enabled;
}

/// Paints the authoritative board anchors without modifying approved artwork.
class DebugBoardOverlay extends StatelessWidget {
  const DebugBoardOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    assert(debugBoardOverlayEnabled);
    return IgnorePointer(
      child: Stack(
        children: [
          for (var index = 0; index < BoardGeometry.trackLength; index++)
            _anchor(index),
          for (final color in PlayerColor.turnOrder) ...[
            for (var lane = 0; lane < BoardGeometry.homeLaneLength; lane++)
              _marker(
                BoardGeometry.homeLanePosition(color, lane),
                '${color.name[0].toUpperCase()}${lane + 1}',
                const Color(0xFF39D5FF),
              ),
            for (var pawn = 0; pawn < 4; pawn++)
              _marker(
                BoardGeometry.yardPosition(color, pawn),
                '${color.name[0].toUpperCase()}Y${pawn + 1}',
                const Color(0xFFFFD36B),
              ),
          ],
          _marker(
            BoardGeometry.finishPosition,
            'FIN',
            const Color(0xFFFFFFFF),
          ),
        ],
      ),
    );
  }

  Widget _marker(
    NormalizedBoardPoint point,
    String label,
    Color accent,
  ) {
    final position = BoardGeometry.canvasPosition(point);
    return Positioned(
      left: position.x - 11,
      top: position.y - 11,
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6000000),
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _anchor(int index) {
    final point = BoardGeometry.canvasPosition(
      BoardGeometry.trackPosition(index),
    );
    final safe = BoardGeometry.safeTrackCells.contains(index);
    return Positioned(
      left: point.x - 11,
      top: point.y - 11,
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: safe ? const Color(0xE6008050) : const Color(0xD9000000),
          border: Border.all(
            color: safe ? const Color(0xFFFFFF00) : Colors.white,
            width: safe ? 2 : 1,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
