import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import 'debug_board_overlay.dart';

/// Renders the approved, pixel-exact board crop at its original canvas
/// location. Pawns continue using the existing 576x1024 board coordinates.
class MatchBoardArtwork extends StatelessWidget {
  const MatchBoardArtwork({super.key, this.showDebugOverlay = false});

  /// Debug-only artwork calibration; never shown in profile/release builds.
  final bool showDebugOverlay;

  static const assetPath = 'assets/images/board/extracted/board_exact.webp';
  static const _referenceWidth = 864.0;
  static const _referenceHeight = 1536.0;
  static const _canvasWidth = 576.0;
  static const _canvasHeight = 1024.0;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFF0C0A10)),
          ),
          Positioned(
            left: 15 / _referenceWidth * _canvasWidth,
            top: 307 / _referenceHeight * _canvasHeight,
            width: 835 / _referenceWidth * _canvasWidth,
            height: 851 / _referenceHeight * _canvasHeight,
            child: Image.asset(
              assetPath,
              key: const Key('board_artwork'),
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF211A0D),
                child: Center(
                  child: Text(
                    'Approved board artwork could not be loaded.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          if (showDebugOverlay && debugBoardOverlayEnabled)
            const Positioned.fill(child: DebugBoardOverlay()),
        ],
      ),
    );
  }
}
