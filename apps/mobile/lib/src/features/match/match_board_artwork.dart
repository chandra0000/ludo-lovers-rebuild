import 'package:flutter/material.dart';

import 'debug_board_overlay.dart';
import '../../theme/app_typography.dart';

/// Renders the approved, pixel-exact board crop at its original canvas
/// location. Pawns continue using the existing 576x1024 board coordinates.
class MatchBoardArtwork extends StatefulWidget {
  const MatchBoardArtwork({
    super.key,
    this.overlays = const [],
    this.canvasScale = 1,
    this.image = const AssetImage(assetPath),
    this.showDebugOverlay = const bool.fromEnvironment('LUDO_DEBUG_BOARD'),
    this.onReadinessChanged,
  }) : assert(canvasScale > 0);

  /// Debug-only artwork calibration; never shown in profile/release builds.
  final bool showDebugOverlay;

  final double canvasScale;
  final List<Widget> overlays;
  final ImageProvider image;
  final ValueChanged<bool>? onReadinessChanged;

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
  State<MatchBoardArtwork> createState() => _MatchBoardArtworkState();
}

class _MatchBoardArtworkState extends State<MatchBoardArtwork> {
  var _attempt = 0;
  var _retrying = false;
  bool? _reportedReady;
  int _readinessGeneration = 0;

  void _reportReadiness(bool ready) {
    if (_reportedReady == ready) return;
    _reportedReady = ready;
    final generation = ++_readinessGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _readinessGeneration) {
        widget.onReadinessChanged?.call(ready);
      }
    });
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.image.evict();
    } catch (error) {
      debugPrint('Board artwork cache eviction failed: $error');
    }
    if (!mounted) return;
    setState(() {
      _attempt++;
      _retrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      key: ValueKey(_attempt),
      image: widget.image,
      fit: BoxFit.fill,
      gaplessPlayback: false,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, artwork, frame, _) => _buildCanvas(
        frame == null
            ? ColoredBox(
                color: const Color(0xFF21162D),
                child: Center(
                  child: _BoardPreparingLabel(canvasScale: widget.canvasScale),
                ),
              )
            : artwork,
        visible: frame != null,
      ),
      errorBuilder: (context, error, stackTrace) => _buildCanvas(
        ColoredBox(
          color: const Color(0xFF211A0D),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12 / widget.canvasScale),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Board image unavailable.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontSize: 14 / widget.canvasScale,
                      ),
                    ),
                    SizedBox(height: 8 / widget.canvasScale),
                    FilledButton(
                      key: const Key('retry_board_artwork'),
                      onPressed: _retrying ? null : _retry,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(
                          48 / widget.canvasScale,
                          48 / widget.canvasScale,
                        ),
                        textStyle: AppTypography.button.copyWith(
                          fontSize: 16 / widget.canvasScale,
                        ),
                      ),
                      child: Semantics(
                        label: 'Retry board image',
                        excludeSemantics: true,
                        child: const Text('Retry', textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        visible: false,
      ),
    );
  }

  Widget _buildCanvas(Widget artwork, {required bool visible}) {
    _reportReadiness(visible);
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF0C0A10))),
        Positioned.fromRect(
          rect: MatchBoardArtwork.artworkRect,
          child: RepaintBoundary(
            key: const Key('board_artwork'),
            child: artwork,
          ),
        ),
        if (widget.overlays.isNotEmpty)
          Positioned.fill(
            child: Visibility(
              visible: visible,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Stack(children: widget.overlays),
            ),
          ),
        if (visible && widget.showDebugOverlay && debugBoardOverlayEnabled)
          const Positioned.fill(child: DebugBoardOverlay()),
      ],
    );
  }
}

class _BoardPreparingLabel extends StatelessWidget {
  const _BoardPreparingLabel({required this.canvasScale});
  final double canvasScale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.all(16 / canvasScale),
        child: Text(
          'Preparing the board…',
          textAlign: TextAlign.center,
          style: AppTypography.status.copyWith(
            color: const Color(0xFFFFE3A0),
            fontSize: 16 / canvasScale,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
