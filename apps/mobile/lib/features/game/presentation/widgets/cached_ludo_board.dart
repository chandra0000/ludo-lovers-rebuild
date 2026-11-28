import 'package:flutter/material.dart';
import '../../../../src/features/match/match_board_artwork.dart';
import '../../../../src/features/match/match_assets.dart';

/// Static artwork stays isolated from motion; preparation owns image listeners.
class CachedLudoBoard extends StatelessWidget {
  const CachedLudoBoard({
    super.key,
    required this.canvasScale,
    this.overlays = const [],
    this.image = MatchAssets.board,
    this.onReadinessChanged,
  });
  final double canvasScale;
  final List<Widget> overlays;
  final ImageProvider image;
  final ValueChanged<bool>? onReadinessChanged;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: MatchBoardArtwork(
          image: image,
          onReadinessChanged: onReadinessChanged,
          canvasScale: canvasScale,
          overlays: overlays,
        ),
      );
}
