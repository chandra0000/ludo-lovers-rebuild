import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/match_player_profile.dart';
import 'match_board_artwork.dart';
import 'player_profile_card.dart';
import 'player_slot_resolver.dart';
import 'royal_game_header.dart';
import 'royal_dice_arena.dart';
import 'profile_social_controls.dart';
import 'social_overlay_coordinator.dart';
import '../../game/domain/player_color.dart';

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
    this.onPlayerChat,
    this.onPlayerEmoji,
    this.social,
    this.thinkingPlayer,
    this.showProfiles = true,
  });
  final ValueChanged<PlayerColor>? onPlayerChat, onPlayerEmoji;
  final SocialOverlayCoordinator? social;
  final PlayerColor? thinkingPlayer;
  final bool showProfiles;
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
          final profileHeight = largeText ? 112.0 : 100.0;
          final slots = PlayerSlotResolver.resolve(
            game,
            profiles,
            thinkingPlayer: thinkingPlayer,
          );
          Widget card(int index) => Expanded(
                child: !showProfiles
                    ? const SizedBox.shrink()
                    : PlayerProfileCard(
                        slot: slots[index],
                        feedback: social?.forPlayer(slots[index].profile.color),
                        socialControls: onPlayerChat == null ||
                                onPlayerEmoji == null
                            ? null
                            : ProfileSocialControls(
                                player: slots[index].profile.color,
                                name: slots[index].profile.displayName,
                                onChat: () =>
                                    onPlayerChat!(slots[index].profile.color),
                                onEmoji: () =>
                                    onPlayerEmoji!(slots[index].profile.color),
                              ),
                      ),
              );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                SizedBox(
                  height: spacious ? 84 : 48,
                  child: RoyalGameHeader(
                    onExit: onExit,
                    spacious: spacious,
                    trailing: reaction,
                  ),
                ),
                if (teamProgress != null)
                  SizedBox(height: teamProgressHeight, child: teamProgress),
                SizedBox(
                  height: profileHeight,
                  child: ClipRect(
                    child: Row(
                      children: [card(0), const SizedBox(width: 12), card(1)],
                    ),
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
                  child: ClipRect(
                    child: Row(
                      children: [
                        card(2),
                        SizedBox(
                          width: spacious ? 104 : 88,
                          child: RoyalDiceArena(child: dice),
                        ),
                        card(3),
                      ],
                    ),
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
