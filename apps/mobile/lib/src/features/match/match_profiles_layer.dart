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
    final initial = profile.displayName.trim().isEmpty
        ? '?'
        : profile.displayName.trim().characters.first.toUpperCase();

    return Semantics(
      label: '${profile.displayName}, ${profile.color.name}, '
          '${profile.isConnected ? 'connected' : 'disconnected'}'
          '${isActive ? ', current turn' : ''}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF018130D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD36B) : accent,
            width: isActive ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accent,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  profile.displayName,
                  key: Key('profile_name_${profile.color.name}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!profile.isConnected)
                const Icon(Icons.wifi_off, size: 14, color: Colors.white70)
              else if (profile.isBot)
                const Icon(Icons.smart_toy_outlined,
                    size: 14, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explicit design-canvas positions, independent from player profile identity.
/// Keep behind a feature gate until baked-in avatars are removed from the
/// approved artwork copy, otherwise both layers would be visible.
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
      PlayerColor.magenta: Offset(12, 733),
      PlayerColor.blue: Offset(378, 733),
    };
    return Stack(
      children: [
        for (final profile in profiles)
          if (seats.containsKey(profile.color))
            Positioned(
              left: seats[profile.color]!.dx,
              top: seats[profile.color]!.dy,
              width: 186,
              height: 46,
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
