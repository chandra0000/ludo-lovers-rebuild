import 'package:flutter/material.dart';

import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import 'match_hud_region_clipper.dart';

/// Match-seat identity is separate from the account and from pawn rules.
/// This widget can consume locally generated or server-supplied profiles.
class MatchPlayerBadge extends StatelessWidget {
  const MatchPlayerBadge({
    super.key,
    required this.profile,
    required this.isActive,
    this.canvasScale = 1,
  }) : assert(canvasScale > 0);

  final MatchPlayerProfile profile;
  final bool isActive;
  final double canvasScale;

  @override
  Widget build(BuildContext context) {
    // Portrait controls compensate for the board transform. Bound design-space
    // growth in constrained/landscape diagnostics so the fixed HUD cannot overflow.
    final presentationScale = canvasScale < .55 ? .55 : canvasScale;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final avatarSize =
        (40 - (textScale - 1) * 16).clamp(32.0, 40.0) / presentationScale;
    final accent = switch (profile.color) {
      PlayerColor.orange => const Color(0xFFFF8928),
      PlayerColor.green => const Color(0xFF33FF28),
      PlayerColor.magenta => const Color(0xFFF428FF),
      PlayerColor.blue => const Color(0xFF289EFF),
    };
    final avatarPath = switch (profile.color) {
      PlayerColor.orange => 'assets/images/board/extracted/avatar_aldo.webp',
      PlayerColor.green => 'assets/images/board/extracted/avatar_you.webp',
      PlayerColor.magenta => 'assets/images/board/extracted/avatar_emma.webp',
      PlayerColor.blue => 'assets/images/board/extracted/avatar_bob.webp',
    };
    final initial = profile.displayName.trim().isEmpty
        ? '?'
        : profile.displayName.trim().characters.first.toUpperCase();

    return Semantics(
      excludeSemantics: true,
      label: '${profile.displayName}, ${profile.color.name}, '
          'seat ${PlayerColor.turnOrder.indexOf(profile.color) + 1}, '
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.displayName,
                      key: Key('profile_name_${profile.color.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14 / presentationScale,
                        height: 1.1,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '${PlayerColor.turnOrder.indexOf(profile.color) + 1}',
                      key: Key('profile_seat_${profile.color.name}'),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10 / presentationScale,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Container(
                        key: Key('profile_avatar_${profile.color.name}'),
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accent,
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
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFFFD36B),
                            fontWeight: FontWeight.w700,
                            fontSize: 10 / presentationScale,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    this.canvasScale = 1,
  }) : assert(canvasScale > 0);

  final List<MatchPlayerProfile> profiles;
  final PlayerColor activeColor;
  final double canvasScale;

  @override
  Widget build(BuildContext context) {
    const seats = <PlayerColor, Offset>{
      PlayerColor.orange: Offset(12, 88),
      PlayerColor.green: Offset(378, 88),
      PlayerColor.magenta: Offset(378, 800),
      PlayerColor.blue: Offset(12, 800),
    };
    return ClipPath(
      clipper: const MatchHudRegionClipper(),
      child: Stack(
        children: [
          for (final profile in profiles)
            if (seats.containsKey(profile.color))
              Positioned(
                left: seats[profile.color]!.dx,
                top: seats[profile.color]!.dy,
                width: 186,
                height: 116,
                child: MatchPlayerBadge(
                  key: Key('profile_${profile.color.name}'),
                  profile: profile,
                  isActive: activeColor == profile.color,
                  canvasScale: canvasScale,
                ),
              ),
        ],
      ),
    );
  }
}
