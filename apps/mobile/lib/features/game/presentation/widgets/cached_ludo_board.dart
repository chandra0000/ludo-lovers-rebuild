import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../src/features/match/match_board_artwork.dart';

/// Caches the approved image independently from animated pawn/dice layers.
/// No board is redrawn or recalibrated; the existing image-frame gate is retained.
class CachedLudoBoard extends StatefulWidget {
  const CachedLudoBoard({
    super.key,
    required this.canvasScale,
    this.overlays = const [],
  });
  final double canvasScale;
  final List<Widget> overlays;

  @override
  State<CachedLudoBoard> createState() => _CachedLudoBoardState();
}

class _CachedLudoBoardState extends State<CachedLudoBoard> {
  bool _warmed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    for (final asset in [
      MatchBoardArtwork.assetPath,
      'assets/images/branding/ludo_lovers_icon.webp',
      for (final name in ['aldo', 'you', 'emma', 'bob'])
        'assets/images/board/extracted/avatar_$name.webp',
    ]) {
      unawaited(
        precacheImage(
          AssetImage(asset),
          context,
          onError: (error, trace) => debugPrint('Match asset warmup: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: MatchBoardArtwork(
          canvasScale: widget.canvasScale,
          overlays: widget.overlays,
        ),
      );
}
