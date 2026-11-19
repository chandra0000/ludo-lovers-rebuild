import 'package:flutter/material.dart';
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
  });
  final Widget? socialControls;
  final LocalSocialFeedback? feedback;
  final PlayerSlot slot;
  @override
  Widget build(BuildContext context) {
    final profile = slot.profile;
    final color = profile.color;
    final accent = color.color;
    final isActive = slot.active && slot.participating;
    final image = switch (color.name) {
      'orange' => 'avatar_aldo.webp',
      'green' => 'avatar_you.webp',
      'magenta' => 'avatar_emma.webp',
      _ => 'avatar_bob.webp',
    };
    return Semantics(
      container: true,
      value: slot.thinking ? 'AI thinking' : null,
      label:
          '${profile.displayName}, ${color.name}, seat ${PlayerColor.turnOrder.indexOf(color) + 1}, ${slot.participating ? profile.presenceLabel : "EMPTY / WAITING"}${isActive ? ', current turn' : ''}',
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  : 'EMPTY / WAITING',
                              key: Key('profile_name_${color.name}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        key: Key('profile_avatar_${color.name}'),
                        width: 40,
                        height: 40,
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
                                  color: accent.withValues(alpha: .35),
                                  size: 32,
                                )
                              : profile.isBot
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.smart_toy_outlined,
                                          key: Key('robot_${color.name}'),
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
                                  : Image.asset(
                                      'assets/images/board/extracted/$image',
                                      fit: BoxFit.cover,
                                      cacheWidth: 128,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.person, color: accent),
                                    ),
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
                          fontSize: 9,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (slot.team != null)
                        Text(
                          'TEAM ${slot.team!.name.toUpperCase()}',
                          key: Key('profile_team_${color.name}'),
                          style: const TextStyle(
                            color: Color(0xFFFFE3A0),
                            fontSize: 9,
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
  }
}
