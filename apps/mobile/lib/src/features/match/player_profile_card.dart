import '../../../features/game/presentation/widgets/seat_avatar.dart';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../game/presentation/player_color_theme.dart';
import 'player_slot_resolver.dart';
import 'royal_crown.dart';
import 'profile_social_controls.dart';
import 'social_overlay_coordinator.dart';
import '../../game/domain/player_color.dart';

/// A stable seat identity. Only the gold turn border follows the active player.
class PlayerProfileCard extends StatelessWidget {
  const PlayerProfileCard({
    super.key,
    required this.slot,
    this.socialControls,
    this.feedback,
    this.noMoves = false,
  });
  final bool noMoves;
  final Widget? socialControls;
  final LocalSocialFeedback? feedback;
  final PlayerSlot slot;
  @override
  Widget build(BuildContext context) {
    final profile = slot.profile;
    final color = profile.color;
    final accent = color.color;
    final isActive = slot.active && slot.participating;
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 17;
        final avatarSize = (constraints.maxHeight * (largeText ? .35 : .54))
            .clamp(largeText ? 40.0 : 52.0, 80.0)
            .clamp(32.0, (constraints.maxWidth - 60).clamp(32.0, 80.0));
        return Semantics(
          container: true,
          value: slot.thinking ? 'AI thinking' : null,
          label:
              '${profile.displayName}, ${color.name}, seat ${PlayerColor.turnOrder.indexOf(color) + 1}, ${slot.participating ? profile.presenceLabel : "EMPTY / WAITING"}${isActive ? ', current turn' : ''}${slot.team != null ? ', team ${slot.team!.name.toUpperCase()}' : ''}',
          child: AnimatedContainer(
            key: Key('profile_${color.name}'),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: 3,
              vertical: socialControls == null ? 4 : 0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(accent, const Color(0xFF171320), .83)!,
                  const Color(0xFF0E0D18),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? const Color(0xFFFFD36B) : accent,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? const [BoxShadow(color: Color(0x44FFD36B), blurRadius: 8)]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: RoyalCrown(size: 10),
                          ),
                        Flexible(
                          child: Text(
                            slot.participating
                                ? profile.displayName
                                : color.name.toUpperCase(),
                            key: Key('profile_name_${color.name}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.playerName.copyWith(
                              height: 1.1,
                              color: isActive ? const Color(0xFFFFE3A0) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  key: Key('profile_avatar_${color.name}'),
                                  width: avatarSize,
                                  height: avatarSize,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: accent, width: 2),
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: .18),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: !slot.participating
                                        ? Icon(
                                            Icons.person_outline,
                                            color:
                                                accent.withValues(alpha: .35),
                                            size: 32,
                                          )
                                        : profile.isBot
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Icon(
                                                    switch (color) {
                                                      PlayerColor.orange =>
                                                        Icons
                                                            .smart_toy_outlined,
                                                      PlayerColor.green =>
                                                        Icons.android,
                                                      PlayerColor.magenta => Icons
                                                          .precision_manufacturing,
                                                      PlayerColor.blue =>
                                                        Icons.rocket_launch,
                                                    },
                                                    key: Key(
                                                      'robot_${color.name}',
                                                    ),
                                                    color: accent,
                                                    size: 32,
                                                  ),
                                                  if (slot.thinking)
                                                    Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: Icon(
                                                        Icons.more_horiz,
                                                        key: Key(
                                                          'ai_thinking_${color.name}',
                                                        ),
                                                        size: 14,
                                                        color: const Color(
                                                          0xFFFFE3A0,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              )
                                            : SeatAvatar(player: color),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  !slot.participating
                                      ? 'EMPTY'
                                      : profile.isBot
                                          ? 'BOT · AI'
                                          : 'LOCAL',
                                  key: Key('profile_seat_${color.name}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (slot.team != null)
                                  Text(
                                    largeText
                                        ? slot.team!.name.toUpperCase()
                                        : 'TEAM ${slot.team!.name.toUpperCase()}',
                                    key: Key('profile_team_${color.name}'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFE3A0),
                                      fontSize: 10,
                                      height: 1.1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (slot.participating && socialControls != null)
                            socialControls!,
                        ],
                      ),
                    ),
                  ],
                ),
                if (noMoves)
                  Positioned(
                    bottom: 0,
                    left: 4,
                    right: 4,
                    child: IgnorePointer(
                      child: Semantics(
                        liveRegion: true,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF211626),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Text(
                              'No moves',
                              key: Key('no_moves_pill'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: Color(0xFFFFE3A0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (feedback != null)
                  Positioned(
                    left: 0,
                    top: 24,
                    width: 56,
                    child: ProfileSocialBubble(
                      feedback: feedback!,
                      name: profile.displayName,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
