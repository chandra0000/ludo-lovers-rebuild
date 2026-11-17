import 'package:flutter/material.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';

/// Stable seat order in the top HUD; independent of turn and board coordinates.
class MatchCompactProfiles extends StatelessWidget {
  const MatchCompactProfiles({
    super.key,
    required this.profiles,
    required this.active,
    this.activePlayers = PlayerColor.turnOrder,
  });
  final List<MatchPlayerProfile> profiles;
  final PlayerColor active;
  final List<PlayerColor> activePlayers;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final color in PlayerColor.turnOrder) ...[
            if (color != PlayerColor.orange) const SizedBox(width: 6),
            Expanded(
              child: _badge(
                context,
                profiles.singleWhere((p) => p.color == color),
              ),
            ),
          ],
        ],
      );

  Widget _badge(BuildContext context, MatchPlayerProfile profile) {
    final color = profile.color;
    final accent = color.color;
    final isActive = active == color;
    final image = switch (color) {
      PlayerColor.orange => 'avatar_aldo.webp',
      PlayerColor.green => 'avatar_you.webp',
      PlayerColor.magenta => 'avatar_emma.webp',
      PlayerColor.blue => 'avatar_bob.webp',
    };
    return Semantics(
      excludeSemantics: true,
      label:
          '${profile.displayName}, ${color.name}, seat ${PlayerColor.turnOrder.indexOf(color) + 1}, ${profile.presenceLabel}${isActive ? ', current turn' : ''}',
      child: AnimatedContainer(
        key: Key('profile_${color.name}'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profile.displayName,
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
            const SizedBox(height: 3),
            Container(
              key: Key('profile_avatar_${color.name}'),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: accent, width: 2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
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
              '${PlayerColor.turnOrder.indexOf(color) + 1} · ${!activePlayers.contains(color) ? 'OUT' : profile.isBot ? 'AI' : 'LOCAL'}',
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
          ],
        ),
      ),
    );
  }
}
