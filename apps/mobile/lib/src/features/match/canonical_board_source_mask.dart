import 'package:flutter/material.dart';

import 'approved_artwork_geometry.dart';

/// Non-destructive board-only calibration from the original approved WebP.
///
/// Unlike a separately exported crop, this view keeps the board pixels in
/// their original portrait source positions. It is a preview-only alternative:
/// a cleaned static board derivative remains preferable for a final release.
class CanonicalBoardSourceMask extends StatelessWidget {
  const CanonicalBoardSourceMask({super.key});

  /// Initial clip limits from the current extracted-board placement.
  ///
  /// These dimensions must be verified against the original image, because
  /// the existing extracted resource was calibrated from an 864x1536 source
  /// whereas the canonical composition is 810x1440. Do not confuse this
  /// visible clip with the logical board topology or pawn anchor coordinates.
  static const Rect boardClip = Rect.fromLTWH(
    15 / 864 * ApprovedArtworkGeometry.canvasWidth,
    307 / 1536 * ApprovedArtworkGeometry.canvasHeight,
    835 / 864 * ApprovedArtworkGeometry.canvasWidth,
    851 / 1536 * ApprovedArtworkGeometry.canvasHeight,
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('canonical_board_mask'),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFF0C0A10)),
          ),
          Positioned.fill(
            child: ClipRect(
              clipper: const _CanvasBoardClipper(),
              child: Image.asset(
                ApprovedArtworkGeometry.referenceAsset,
                key: const Key('canonical_board_source'),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                cacheWidth: ApprovedArtworkGeometry.sourceWidth.toInt(),
                excludeFromSemantics: true,
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
          ),
        ],
      ),
    );
  }
}

class _CanvasBoardClipper extends CustomClipper<Rect> {
  const _CanvasBoardClipper();

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      CanonicalBoardSourceMask.boardClip.left *
          size.width /
          ApprovedArtworkGeometry.canvasWidth,
      CanonicalBoardSourceMask.boardClip.top *
          size.height /
          ApprovedArtworkGeometry.canvasHeight,
      CanonicalBoardSourceMask.boardClip.width *
          size.width /
          ApprovedArtworkGeometry.canvasWidth,
      CanonicalBoardSourceMask.boardClip.height *
          size.height /
          ApprovedArtworkGeometry.canvasHeight,
    );
  }

  @override
  bool shouldReclip(covariant _CanvasBoardClipper oldClipper) => false;
}
