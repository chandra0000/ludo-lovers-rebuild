import 'package:flutter/material.dart';

class MatchUtilityBar extends StatelessWidget {
  const MatchUtilityBar({
    super.key,
    required this.onChat,
    required this.onMore,
  });
  final VoidCallback onChat, onMore;
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
