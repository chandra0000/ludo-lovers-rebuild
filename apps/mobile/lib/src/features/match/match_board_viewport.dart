import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import 'match_surface_chrome.dart';
import 'match_adaptive_layout.dart';

/// Preserves the approved 576x1024 board coordinate space at every screen size.
class MatchBoardViewport extends StatelessWidget {
  const MatchBoardViewport({super.key, required this.builder});

  final Widget Function(BuildContext context, double canvasScale) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = MatchAdaptiveLayout.resolve(
          available: constraints.biggest,
          canvas: const Size(
            BoardGeometry.canvasWidth,
            BoardGeometry.canvasHeight,
          ),
        );
        final scale = layout.scale;
        return MatchSurfaceChrome(
          child: Center(
            child: RepaintBoundary(
              key: const Key('match_canvas_capture'),
              child: SizedBox(
                key: const Key('match_canvas'),
                width: BoardGeometry.canvasWidth * scale,
                height: BoardGeometry.canvasHeight * scale,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: BoardGeometry.canvasWidth,
                    height: BoardGeometry.canvasHeight,
                    child: builder(context, scale),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
