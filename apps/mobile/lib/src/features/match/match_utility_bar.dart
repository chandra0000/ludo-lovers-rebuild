import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('chat_button'),
              onPressed: onChat,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Local Chat'),
            ),
          ),
          if (legal.length > 1)
            PopupMenuButton<int>(
              key: const Key('accessible_pawn_chooser'),
              tooltip: 'Choose a legal pawn',
              onSelected: onPawn,
              constraints: const BoxConstraints(minWidth: 120),
              itemBuilder: (_) => [
                for (final pawn in legal)
                  PopupMenuItem(
                    value: pawn,
                    height: 48,
                    child: Text('Pawn ${pawn + 1}'),
                  ),
              ],
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.touch_app),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('more_button'),
              onPressed: onMore,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.tune, size: 20),
              label: const Text('Settings'),
            ),
          ),
        ],
      );
}
