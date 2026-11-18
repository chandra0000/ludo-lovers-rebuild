import 'package:flutter/material.dart';
import '../../game/presentation/player_color_theme.dart';
import 'player_slot_resolver.dart';
import 'royal_crown.dart';
import '../../game/domain/player_color.dart';

/// A stable seat identity. Only the gold turn border follows the active player.
class PlayerProfileCard extends StatelessWidget {
  const PlayerProfileCard({super.key, required this.slot});
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
      label:
          '${profile.displayName}, ${color.name}, seat ${PlayerColor.turnOrder.indexOf(color) + 1}, ${slot.participating ? profile.presenceLabel : "EMPTY / WAITING"}${isActive ? ', current turn' : ''}',
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.participating ? profile.displayName : 'EMPTY / WAITING',
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
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .18),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: profile.isBot && slot.participating
                        ? Icon(
                            Icons.smart_toy_outlined,
                            key: Key('robot_${color.name}'),
                            color: accent,
                            size: 32,
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
                  '${PlayerColor.turnOrder.indexOf(color) + 1} · ${!slot.participating ? 'EMPTY' : profile.isBot ? 'BOT · AI' : 'LOCAL'}${slot.team == null ? '' : ' · ${slot.team!.name.toUpperCase()}'}',
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
            if (isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Semantics(
                  label: 'Active turn',
                  child: const RoyalCrown(size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
