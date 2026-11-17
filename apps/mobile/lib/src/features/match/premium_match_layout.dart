import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game/domain/board_geometry.dart';
import 'match_board_artwork.dart';

/// Independent logical-pixel HUD regions around one canonical board transform.
class PremiumMatchLayout extends StatelessWidget {
  const PremiumMatchLayout({
    super.key,
    required this.profiles,
    required this.controls,
    required this.onExit,
    required this.reaction,
    required this.boardBuilder,
    this.title = 'LOCAL MATCH',
  });
  final String title;
  final Widget profiles;
  final Widget controls;
  final Widget reaction;
  final VoidCallback onExit;
  final Widget Function(BuildContext, double) boardBuilder;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                key: const Key('match_top_rail'),
                children: [
                  IconButton(
                    key: const Key('exit_match'),
                    tooltip: 'Exit match',
                    constraints:
                        const BoxConstraints.tightFor(width: 48, height: 48),
                    onPressed: onExit,
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFFFFD36B)),
                  ),
                  Image.asset(
                    'assets/images/branding/ludo_lovers_icon.webp',
                    key: const Key('match_brand_mark'),
                    width: 36,
                    height: 36,
                    cacheWidth: 128,
                    semanticLabel: 'Ludo Lovers',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD36B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 64, height: 48, child: reaction),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(14) > 17 ? 96 : 84,
              child: profiles,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = math.min(box.maxWidth, box.maxHeight);
                    final scale = side / BoardGeometry.canvasWidth;
                    return SizedBox(
                      key: const Key('board_stage'),
                      width: side,
                      height: side,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: 0,
                            top: -MatchBoardArtwork.artworkRect.top * scale,
                            width: side,
                            height: BoardGeometry.canvasHeight * scale,
                            child: RepaintBoundary(
                              key: const Key('match_canvas_capture'),
                              child: SizedBox(
                                key: const Key('match_canvas'),
                                width: side,
                                height: BoardGeometry.canvasHeight * scale,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: SizedBox(
                                    width: BoardGeometry.canvasWidth,
                                    height: BoardGeometry.canvasHeight,
                                    child: boardBuilder(context, scale),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('match_bottom_rail'),
              height: 144,
              child: controls,
            ),
          ],
        ),
      );
}
