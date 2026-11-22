import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/match_player_profile.dart';
import 'match_board_artwork.dart';
import 'player_profile_card.dart';
import 'player_slot_resolver.dart';

/// One live surface for FFA, 1v1, AI and Team Up; contains no gameplay policies.
class GameBoardScaffold extends StatelessWidget {
  const GameBoardScaffold({
    super.key,
    required this.game,
    required this.profiles,
    required this.onExit,
    required this.dice,
    required this.utilities,
    required this.status,
    required this.reaction,
    required this.boardBuilder,
    this.teamProgress,
    this.teamProgressHeight = 40,
  });
  final LudoGame game;
  final List<MatchPlayerProfile> profiles;
  final VoidCallback onExit;
  final Widget dice, utilities, status, reaction;
  final Widget? teamProgress;
  final double teamProgressHeight;
  final Widget Function(BuildContext, double) boardBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final spacious = box.maxHeight >= 760;
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 17;
          final profileHeight = largeText ? 112.0 : 96.0;
          final slots = PlayerSlotResolver.resolve(game, profiles);
          Widget card(int index) =>
              Expanded(child: PlayerProfileCard(slot: slots[index]));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                SizedBox(
                  height: spacious ? 76 : 48,
                  child: Stack(
                    key: const Key('match_top_rail'),
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          key: const Key('exit_match'),
                          tooltip: 'Exit match',
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          onPressed: onExit,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFFFE3A0),
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/branding/ludo_lovers_icon.webp',
                        key: const Key('match_brand_mark'),
                        width: spacious ? 72 : 44,
                        height: spacious ? 72 : 44,
                        cacheWidth: 216,
                        semanticLabel: 'Ludo Lovers',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(width: 48, height: 48, child: reaction),
                      ),
                    ],
                  ),
                ),
                if (teamProgress != null)
                  SizedBox(height: teamProgressHeight, child: teamProgress),
                SizedBox(
                  height: profileHeight,
                  child: Row(
                    children: [card(0), const SizedBox(width: 12), card(1)],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, boardBox) {
                        final side =
                            math.min(boardBox.maxWidth, boardBox.maxHeight);
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
                const SizedBox(height: 4),
                SizedBox(
                  key: const Key('match_bottom_rail'),
                  height: profileHeight,
                  child: Row(
                    children: [
                      card(2),
                      SizedBox(width: spacious ? 104 : 88, child: dice),
                      card(3),
                    ],
                  ),
                ),
                SizedBox(height: largeText ? 40 : 24, child: status),
                SizedBox(height: 48, child: utilities),
              ],
            ),
          );
        },
      );
}
