import 'package:flutter/material.dart';

import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';

/// Match-seat identity is separate from the account and from pawn rules.
/// This widget can consume locally generated or server-supplied profiles.
class MatchPlayerBadge extends StatelessWidget {
  const MatchPlayerBadge({
    super.key,
    required this.profile,
    required this.isActive,
  });

  final MatchPlayerProfile profile;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final accent = switch (profile.color) {
      PlayerColor.orange => const Color(0xFFFF8928),
      PlayerColor.green => const Color(0xFF33FF28),
      PlayerColor.magenta => const Color(0xFFF428FF),
      PlayerColor.blue => const Color(0xFF289EFF),
    };
    final avatarPath = switch (profile.color) {
      PlayerColor.orange => 'assets/images/board/extracted/avatar_aldo.webp',
      PlayerColor.green => 'assets/images/board/extracted/avatar_you.webp',
      PlayerColor.magenta => 'assets/images/board/extracted/avatar_bob.webp',
      PlayerColor.blue => 'assets/images/board/extracted/avatar_emma.webp',
    };
    final initial = profile.displayName.trim().isEmpty
        ? '?'
        : profile.displayName.trim().characters.first.toUpperCase();

    return Semantics(
      excludeSemantics: true,
      label: '${profile.displayName}, ${profile.color.name}, '
          '${profile.presenceLabel.toLowerCase()}'
          '${isActive ? ', current turn' : ''}',
      child: AnimatedContainer(
        duration: MediaQuery.maybeOf(context)?.disableAnimations == true
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: const Color(0xF018130D),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? const [
                  BoxShadow(color: Color(0x55FFD36B), blurRadius: 12),
                ]
              : null,
          border: Border.all(
            color: isActive ? const Color(0xFFFFD36B) : accent,
            width: isActive ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: accent,
                child: ClipOval(
                  child: Image.asset(
                    avatarPath,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    cacheWidth: 192,
                    cacheHeight: 192,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      key: Key('profile_name_${profile.color.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (!profile.isLocalSeat && !profile.isConnected)
                          const Icon(
                            Icons.wifi_off,
                            size: 13,
                            color: Colors.white70,
                          )
                        else if (profile.isBot)
                          const Icon(
                            Icons.smart_toy_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            profile.presenceLabel,
                            key: Key('profile_status_${profile.color.name}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFD36B),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explicit design-canvas positions, independent from player profile identity.
/// Seats sit outside the board-only artwork, so no baked-in avatars overlap.
class MatchProfilesLayer extends StatelessWidget {
  const MatchProfilesLayer({
    super.key,
    required this.profiles,
    required this.activeColor,
  });

  final List<MatchPlayerProfile> profiles;
  final PlayerColor activeColor;

  @override
  Widget build(BuildContext context) {
    const seats = <PlayerColor, Offset>{
      PlayerColor.orange: Offset(12, 102),
      PlayerColor.green: Offset(378, 102),
      PlayerColor.magenta: Offset(12, 850),
      PlayerColor.blue: Offset(378, 850),
    };
    return Stack(
      children: [
        for (final profile in profiles)
          if (seats.containsKey(profile.color))
            Positioned(
              left: seats[profile.color]!.dx,
              top: seats[profile.color]!.dy,
              width: 186,
              height: 60,
              child: MatchPlayerBadge(
                key: Key('profile_${profile.color.name}'),
                profile: profile,
                isActive: activeColor == profile.color,
              ),
            ),
      ],
    );
  }
}
