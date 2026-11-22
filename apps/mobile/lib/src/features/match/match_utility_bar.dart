import 'package:flutter/material.dart';
import 'pawn_chooser.dart';

class MatchUtilityBar extends StatelessWidget {
  const MatchUtilityBar({
    super.key,
    required this.onChat,
    required this.onMore,
    required this.legal,
    required this.onPawn,
  });
  final VoidCallback onChat, onMore;
  final List<int> legal;
  final ValueChanged<int> onPawn;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(16) >= 28) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            key: const Key('chat_button'),
            tooltip: 'Local Chat',
            onPressed: onChat,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          if (legal.length > 1)
            IconButton(
              key: const Key('accessible_pawn_chooser'),
              tooltip: 'Choose a legal pawn',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => showPawnChooser(context, legal, onPawn),
              icon: const Icon(Icons.touch_app),
            ),
          IconButton(
            key: const Key('more_button'),
            tooltip: 'Settings',
            onPressed: onMore,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.tune),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('chat_button'),
            onPressed: onChat,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFE3A0),
              side: const BorderSide(color: Color(0x88D9AD55)),
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text('Local Chat'),
          ),
        ),
        if (legal.length > 1)
          IconButton(
            key: const Key('accessible_pawn_chooser'),
            tooltip: 'Choose a legal pawn',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => showPawnChooser(context, legal, onPawn),
            icon: const Icon(Icons.touch_app),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('more_button'),
            onPressed: onMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFE3A0),
              side: const BorderSide(color: Color(0x88D9AD55)),
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.tune, size: 20),
            label: const Text('Settings'),
          ),
        ),
      ],
    );
  }
}
