import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';

/// Presentation-only status and accessible legal choices from MatchSession.
class MatchHudOverlay extends StatelessWidget {
  const MatchHudOverlay({
    super.key,
    required this.statusText,
    required this.activePlayer,
    this.actionInstruction = 'Roll dice',
    this.canvasScale = 1,
    this.legalPawnIndices = const [],
    this.onPawnSelected,
    this.inline = false,
  }) : assert(canvasScale > 0);

  final bool inline;
  final String statusText;
  final PlayerColor activePlayer;
  final String actionInstruction;
  final double canvasScale;
  final List<int> legalPawnIndices;
  final ValueChanged<int>? onPawnSelected;

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      liveRegion: true,
      label:
          'Current turn: ${activePlayer.name}. $statusText. $actionInstruction',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2111017),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activePlayer.color, width: 2),
          boxShadow: [
            BoxShadow(
              color: activePlayer.color.withValues(alpha: 0.18),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                actionInstruction,
                key: const Key('match_action_instruction'),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 / canvasScale,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                statusText,
                key: const Key('turn_status'),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: activePlayer.color,
                  fontSize: 10 / canvasScale,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final control = IgnorePointer(child: content);
    if (inline) return control;
    return Positioned(
      left: 120,
      top: 920,
      width: 240,
      height: math.max(88, 48 / canvasScale),
      child: control,
    );
  }
}
