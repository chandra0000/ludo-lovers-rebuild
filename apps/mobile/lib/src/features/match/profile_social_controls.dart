import 'package:flutter/material.dart';
import '../../game/domain/player_color.dart';
import 'social_overlay_coordinator.dart';

class ProfileSocialControls extends StatelessWidget {
  const ProfileSocialControls({
    super.key,
    required this.player,
    required this.name,
    required this.onChat,
    required this.onEmoji,
  });
  final PlayerColor player;
  final String name;
  final VoidCallback onChat, onEmoji;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: Key('profile_chat_${player.name}'),
              tooltip: 'Local chat as $name',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              onPressed: onChat,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Color(0xFFFFE3A0),
              ),
            ),
            IconButton(
              key: Key('profile_emoji_${player.name}'),
              tooltip: 'Local emoji as $name',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              onPressed: onEmoji,
              icon: const Icon(
                Icons.emoji_emotions_outlined,
                size: 20,
                color: Color(0xFFFFE3A0),
              ),
            ),
          ],
        ),
      );
}

/// Bubbles live inside the originating avatar card, never above board cells.
class ProfileSocialBubble extends StatelessWidget {
  const ProfileSocialBubble({
    super.key,
    required this.feedback,
    required this.name,
  });
  final LocalSocialFeedback feedback;
  final String name;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Semantics(
          liveRegion: true,
          label: 'On this device, $name: ${feedback.text}',
          child: TweenAnimationBuilder<double>(
            key: ValueKey(feedback.sequence),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            tween: Tween(begin: .85, end: 1),
            curve: Curves.easeOutCubic,
            builder: (_, value, child) => Transform.translate(
              offset: Offset(0, (1 - value) * 24),
              child: Opacity(opacity: value, child: child),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFA12121A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD9AD55)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  feedback.text,
                  key: const Key('local_reaction_toast'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFE3A0),
                    fontSize: 14,
                    fontFamilyFallback: [
                      'Noto Color Emoji',
                      'Apple Color Emoji',
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
