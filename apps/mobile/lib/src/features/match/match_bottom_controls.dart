import 'package:flutter/material.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/luxury_dice.dart';
import 'match_hud_overlay.dart';

class MatchBottomControls extends StatelessWidget {
  const MatchBottomControls({
    super.key,
    required this.value,
    required this.rollId,
    required this.canRoll,
    required this.waiting,
    required this.onRoll,
    required this.onDiceComplete,
    required this.status,
    required this.instruction,
    required this.active,
    required this.legal,
    required this.onPawn,
    required this.onChat,
    required this.onReaction,
    required this.onMore,
  });
  final int? value;
  final int rollId;
  final bool canRoll;
  final bool waiting;
  final VoidCallback onRoll;
  final VoidCallback onDiceComplete;
  final String status;
  final String instruction;
  final PlayerColor active;
  final List<int> legal;
  final ValueChanged<int> onPawn;
  final VoidCallback onChat;
  final VoidCallback onReaction;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 96,
            child: Row(
              children: [
                SizedBox(
                  key: const Key('roll_dice'),
                  width: 96,
                  height: 96,
                  child: LuxuryDiceButton(
                    key: const Key('animated_dice'),
                    size: 72,
                    targetValue: value,
                    rollId: rollId,
                    canRoll: canRoll,
                    isWaitingForRoll: waiting,
                    onRollRequested: onRoll,
                    onAnimationComplete: onDiceComplete,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: MatchHudOverlay(
                      inline: true,
                      statusText: status,
                      activePlayer: active,
                      actionInstruction: instruction,
                      legalPawnIndices: legal,
                      onPawnSelected: onPawn,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                _button(
                  'chat_button',
                  'Local chat',
                  Icons.chat_bubble_outline,
                  onChat,
                ),
                const SizedBox(width: 8),
                _button(
                  'quick_reactions_button',
                  'Emoji',
                  Icons.emoji_emotions_outlined,
                  onReaction,
                ),
                const SizedBox(width: 8),
                _button('more_button', 'Settings', Icons.tune, onMore),
              ],
            ),
          ),
        ],
      );

  Widget _button(
    String key,
    String label,
    IconData icon,
    VoidCallback callback,
  ) =>
      Expanded(
        child: OutlinedButton.icon(
          key: Key(key),
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: const Color(0xFFFFD36B),
            side: const BorderSide(color: Color(0x88D6A544)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
}
