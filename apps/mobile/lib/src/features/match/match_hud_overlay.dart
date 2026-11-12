import 'package:flutter/material.dart';

import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';

/// Presentation-only turn status; does not own or mutate match state.
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
      left: 200,
      top: 924,
      width: 176,
      height: 32,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xE6080808),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              key: const Key('turn_status'),
              maxLines: 1,
              style: TextStyle(
                color: activePlayer.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
