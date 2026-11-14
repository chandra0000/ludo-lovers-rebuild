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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(accent, const Color(0xFF19131C), .82)!,
              const Color(0xFF0B0C16),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x55FFD36B),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
          border: Border.all(
            color: isActive ? const Color(0xFFFFD36B) : accent,
            width: isActive ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.displayName,
                      key: Key('profile_name_${profile.color.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      key: Key('profile_avatar_${profile.color.name}'),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? const Color(0xFFFFD36B) : accent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          avatarPath,
                          fit: BoxFit.cover,
                          cacheWidth: 192,
                          cacheHeight: 192,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isActive)
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFFFFD36B),
                        size: 18,
                      ),
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
                    Text(
                      profile.presenceLabel,
                      key: Key('profile_status_${profile.color.name}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFD36B),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
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
      PlayerColor.orange: Offset(12, 88),
      PlayerColor.green: Offset(378, 88),
      PlayerColor.magenta: Offset(12, 832),
      PlayerColor.blue: Offset(378, 832),
    };
    return Stack(
      children: [
        for (final profile in profiles)
          if (seats.containsKey(profile.color))
            Positioned(
              left: seats[profile.color]!.dx,
              top: seats[profile.color]!.dy,
              width: 186,
              height: 78,
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
