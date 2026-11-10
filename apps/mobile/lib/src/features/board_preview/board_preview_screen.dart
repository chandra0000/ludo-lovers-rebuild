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
                  'Canonical artwork · coordinate crosshairs · provisional',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: const Key('board_preview_capture'),
                    child: AspectRatio(
                      aspectRatio:
                          BoardGeometry.canvasWidth / BoardGeometry.canvasHeight,
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
                              crosshairKey: BoardGeometry.safeTrackCells.contains(index)
                                  ? Key('preview_track_${index}_crosshair')
                                  : null,
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
                            crosshairKey: const Key('preview_finish_crosshair'),
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
    Key? crosshairKey,
    required Key key,
  }) {
    final point = BoardGeometry.canvasPosition(cell.normalizedCenter);
    return Positioned(
      left: point.x / BoardGeometry.canvasWidth * width -
          (size + (crosshairKey == null ? 0 : 8)) / 2,
      top: point.y / BoardGeometry.canvasHeight * height -
          (size + (crosshairKey == null ? 0 : 8)) / 2,
      child: IgnorePointer(
        child: SizedBox(
          width: size + (crosshairKey == null ? 0 : 8),
          height: size + (crosshairKey == null ? 0 : 8),
          child: Stack(
            key: crosshairKey,
            alignment: Alignment.center,
            children: [
              Container(
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
              if (crosshairKey != null) ...[
                Container(width: size + 8, height: 1, color: color),
                Container(width: 1, height: size + 8, color: color),
              ],
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
      left: point.x / BoardGeometry.canvasWidth * width - 9,
      top: point.y / BoardGeometry.canvasHeight * height - 9,
      child: IgnorePointer(
        child: SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            key: Key('preview_${color.name}_${pawnIndex}_crosshair'),
            alignment: Alignment.center,
            children: [
              Container(
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
              Container(width: 18, height: 1, color: color.color),
              Container(width: 1, height: 18, color: color.color),
            ],
          ),
        ),
      ),
    );
  }
}
