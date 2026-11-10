import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';

/// Read-only diagnostic view. Coordinates are provisional until pixel-measured.
class BoardPreviewScreen extends StatelessWidget {
  const BoardPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          title: const Text('BOARD PREVIEW'),
          backgroundColor: const Color(0xFF100D08),
          foregroundColor: const Color(0xFFFFC857),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'Canonical artwork · geometry audit overlay · provisional',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: BoardGeometry.canvasWidth / BoardGeometry.canvasHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        key: const Key('board_preview_canvas'),
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/board/ludo_board_glass.webp',
                            key: const Key('board_preview_artwork'),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                              color: Color(0xFF111111),
                              child: Center(
                                child: Text(
                                  'Canonical board artwork failed to load.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                          for (var index = 0;
                              index < BoardGeometry.sharedTrack.length;
                              index++)
                            _cellMarker(
                              BoardGeometry.sharedTrack[index],
                              constraints.maxWidth,
                              constraints.maxHeight,
                              color: BoardGeometry.safeTrackCells.contains(index)
                                  ? const Color(0xFFFFC857)
                                  : BoardGeometry.cornerConnectorIndexes
                                          .contains(index)
                                      ? Colors.redAccent
                                      : Colors.white70,
                              size: BoardGeometry.safeTrackCells.contains(index)
                                  ? 9
                                  : 5,
                              key: Key('preview_track_$index'),
                            ),
                          for (final color in PlayerColor.turnOrder)
                            for (var lane = 0;
                                lane < BoardGeometry.seats[color]!.homeLane.length;
                                lane++)
                              _cellMarker(
                                BoardGeometry.seats[color]!.homeLane[lane],
                                constraints.maxWidth,
                                constraints.maxHeight,
                                color: color.color,
                                size: 7,
                                key: Key('preview_lane_${color.name}_$lane'),
                              ),
                          _cellMarker(
                            BoardGeometry.finishCell,
                            constraints.maxWidth,
                            constraints.maxHeight,
                            color: const Color(0xFFFFC857),
                            size: 13,
                            key: const Key('preview_finish'),
                          ),
                          for (final color in PlayerColor.turnOrder)
                            for (var index = 0; index < 4; index++)
                              _yardMarker(
                                color,
                                index,
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  'White = shared route · Gold = safe/finish · Red = candidate '
                  'connector · Player colour = home lane and yard sockets. '
                  'Diagnostic only; source-pixel calibration and device '
                  'verification are still required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _cellMarker(
    BoardCell cell,
    double width,
    double height, {
    required Color color,
    required double size,
    required Key key,
  }) {
    final point = BoardGeometry.canvasPosition(cell.normalizedCenter);
    return Positioned(
      left: point.x / BoardGeometry.canvasWidth * width - size / 2,
      top: point.y / BoardGeometry.canvasHeight * height - size / 2,
      child: IgnorePointer(
        child: Container(
          key: key,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .9),
            border: Border.all(color: Colors.black, width: .7),
            boxShadow: const [
              BoxShadow(color: Color(0x88000000), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yardMarker(
    PlayerColor color,
    int pawnIndex,
    double width,
    double height,
  ) {
    final point = BoardGeometry.canvasPosition(
      BoardGeometry.normalizedPosition(color, -1, pawnIndex),
    );
    return Positioned(
      left: point.x / BoardGeometry.canvasWidth * width - 5,
      top: point.y / BoardGeometry.canvasHeight * height - 5,
      child: IgnorePointer(
        child: Container(
          key: Key('preview_${color.name}_$pawnIndex'),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.color.withValues(alpha: .9),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x99FFC857), blurRadius: 5),
            ],
          ),
        ),
      ),
    );
  }
}
