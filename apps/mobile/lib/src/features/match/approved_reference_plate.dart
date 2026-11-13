import 'package:flutter/material.dart';

import 'approved_artwork_geometry.dart';

/// Faithful full-screen visual plate. Keep the user-approved source immutable.
///
/// An approved clean derivative will eventually replace baked names, avatars,
/// turn text and the decorative die. Until that exists this is a preview-only
/// rendering mode, never a release-ready substitution for live profile data.
class ApprovedReferencePlate extends StatelessWidget {
  const ApprovedReferencePlate({
    super.key,
    required this.canvasScale,
  });

  final double canvasScale;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final requestedDecodeWidth =
        (ApprovedArtworkGeometry.canvasWidth * canvasScale * dpr)
            .ceil()
            .clamp(1, ApprovedArtworkGeometry.sourceWidth.toInt())
            .toInt();

    return RepaintBoundary(
      key: const Key('approved_artwork_plate'),
      child: SizedBox.expand(
        child: Image.asset(
          ApprovedArtworkGeometry.referenceAsset,
          key: const Key('approved_full_artwork'),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          cacheWidth: requestedDecodeWidth,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: Color(0xFF100A07),
            child: Center(
              child: Text(
                'Approved artwork is unavailable.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
