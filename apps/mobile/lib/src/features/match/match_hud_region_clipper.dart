import 'package:flutter/rendering.dart';

import 'match_board_artwork.dart';

/// Prevent profile glow and dice motion from painting over protected artwork.
/// Only presentation layers use this; geometry and pawn hitboxes are unchanged.
class MatchHudRegionClipper extends CustomClipper<Path> {
  const MatchHudRegionClipper();

  @override
  Path getClip(Size size) => Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(MatchBoardArtwork.artworkRect),
      );

  @override
  bool shouldReclip(MatchHudRegionClipper oldClipper) => false;
}
