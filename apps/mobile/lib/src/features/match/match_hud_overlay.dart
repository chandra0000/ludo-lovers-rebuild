import 'package:flutter/material.dart';

import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';

/// High-contrast, presentation-only turn status; match state stays authoritative.
class MatchHudOverlay extends StatelessWidget {
  const MatchHudOverlay({
    super.key,
    required this.statusText,
    required this.activePlayer,
  });

  final String statusText;
  final PlayerColor activePlayer;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 172,
      top: 916,
      width: 208,
      height: 50,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          label: 'Current turn: ${activePlayer.name}. $statusText',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF2111017),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activePlayer.color,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activePlayer.color.withValues(alpha: 0.18),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  statusText,
                  key: const Key('turn_status'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activePlayer.color,
                    fontSize: 14,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
