import 'package:flutter/material.dart';

/// Immutable artwork layer. Gameplay widgets are rendered above this layer.
///
/// The canonical source is retained unchanged until a clean, board-only asset
/// is approved. Keeping this boundary separate avoids rebuilding the image
/// when dice, pawn, or chat state changes.
class MatchBoardArtwork extends StatelessWidget {
  const MatchBoardArtwork({super.key});

  static const assetPath = 'assets/images/board/ludo_board_glass.webp';

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.asset(
        assetPath,
        key: const Key('board_artwork'),
        fit: BoxFit.fill,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: Color(0xFF111111),
          child: Center(
            child: Text(
              'Game artwork could not be loaded.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
