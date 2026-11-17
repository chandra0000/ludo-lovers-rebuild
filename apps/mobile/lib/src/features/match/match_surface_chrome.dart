import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';

/// Fills the unused space on taller phones without resizing or cropping
/// the approved 576x1024 gameplay composition.
class MatchSurfaceChrome extends StatelessWidget {
  const MatchSurfaceChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / BoardGeometry.canvasWidth,
          constraints.maxHeight / BoardGeometry.canvasHeight,
        );
        final stageHeight = BoardGeometry.canvasHeight * scale;
        final railHeight = math.max(
          0.0,
          (constraints.maxHeight - stageHeight) / 2,
        );

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF10101E),
                Color(0xFF080911),
                Color(0xFF15101D),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (railHeight >= 40)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: railHeight,
                  child: const Center(
                    child: Text(
                      'LOCAL MATCH',
                      key: Key('match_top_rail'),
                      maxLines: 1,
                      style: TextStyle(
                        color: Color(0x99FFD36B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ),
              if (railHeight >= 40)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: railHeight,
                  child: const Center(
                    child: Text(
                      'FOUR SEATS  •  ONE BOARD',
                      key: Key('match_bottom_rail'),
                      maxLines: 1,
                      style: TextStyle(
                        color: Color(0x88FFD36B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(child: child),
            ],
          ),
        );
      },
    );
  }
}
