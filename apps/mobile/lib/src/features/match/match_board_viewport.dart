import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';

/// Preserves the approved 576x1024 board coordinate space at every screen size.
class MatchBoardViewport extends StatelessWidget {
  const MatchBoardViewport({super.key, required this.builder});

  final Widget Function(BuildContext context, double canvasScale) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / BoardGeometry.canvasWidth,
          constraints.maxHeight / BoardGeometry.canvasHeight,
        );
        return Center(
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
        );
      },
    );
  }
}
