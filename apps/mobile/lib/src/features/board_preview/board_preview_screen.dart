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
                  'Canonical artwork preview · overlay positions are provisional',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/board/ludo_board_glass.webp',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
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
                  'Diagnostic only — track, connector, safe-cell, lane and yard '
                  'anchors require pixel measurement and device verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );

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
