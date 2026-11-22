import 'package:flutter/material.dart';

import 'debug_board_overlay.dart';

/// Renders the approved, pixel-exact board crop at its original canvas
/// location. Pawns continue using the existing 576x1024 board coordinates.
class MatchBoardArtwork extends StatelessWidget {
  const MatchBoardArtwork({
    super.key,
    this.overlays = const [],
    this.image = const AssetImage(assetPath),
    this.showDebugOverlay = const bool.fromEnvironment('LUDO_DEBUG_BOARD'),
  });

  /// Debug-only artwork calibration; never shown in profile/release builds.
  final bool showDebugOverlay;

  final List<Widget> overlays;
  final ImageProvider image;

  static const assetPath = 'assets/images/board/extracted/board_exact.webp';
  static const _referenceWidth = 864.0;
  static const _referenceHeight = 1536.0;
  static const _canvasWidth = 576.0;
  static const _canvasHeight = 1024.0;

  /// Existing derivative registration; shared only by presentation clipping.
  static const artworkRect = Rect.fromLTWH(
    15 / _referenceWidth * _canvasWidth,
    307 / _referenceHeight * _canvasHeight,
    835 / _referenceWidth * _canvasWidth,
    851 / _referenceHeight * _canvasHeight,
  );

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, artwork, frame, _) =>
          _buildCanvas(artwork, visible: frame != null),
      errorBuilder: (context, error, stackTrace) => _buildCanvas(
        const ColoredBox(
          color: Color(0xFF211A0D),
          child: Center(
            child: Text(
              'Approved board artwork could not be loaded.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        visible: false,
      ),
    );
  }

  Widget _buildCanvas(Widget artwork, {required bool visible}) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF0C0A10))),
        Positioned.fromRect(
          rect: artworkRect,
          child: RepaintBoundary(
            key: const Key('board_artwork'),
            child: artwork,
          ),
        ),
        if (overlays.isNotEmpty)
          Positioned.fill(
            child: Visibility(
              visible: visible,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Stack(children: overlays),
            ),
          ),
        if (showDebugOverlay && debugBoardOverlayEnabled)
          const Positioned.fill(child: DebugBoardOverlay()),
      ],
    );
  }
}
