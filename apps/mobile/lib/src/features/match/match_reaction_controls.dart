import 'package:flutter/material.dart';

import 'local_match_chat_sheet.dart';

/// Separate, local-only emoji affordance. Does not send network messages.
class MatchReactionButton extends StatelessWidget {
  const MatchReactionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 392,
      top: 928,
      width: 84,
      height: 84,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0211A0D),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD36B)),
        ),
        child: IconButton(
          key: const Key('quick_reactions_button'),
          tooltip: 'Quick emoji reactions on this device',
          onPressed: onPressed,
          icon: const Icon(
            Icons.emoji_emotions_outlined,
            size: 32,
            color: Color(0xFFFFD36B),
          ),
        ),
      ),
    );
  }
}

class MatchReactionToast extends StatelessWidget {
  const MatchReactionToast({super.key, required this.reaction});

  final String? reaction;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 392,
      top: 778,
      width: 92,
      height: 70,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: MediaQuery.maybeOf(context)?.disableAnimations == true
              ? Duration.zero
              : const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .25),
                end: Offset.zero,
              ).animate(animation),
              child: ScaleTransition(scale: animation, child: child),
            ),
          ),
          child: reaction == null
              ? const SizedBox.shrink()
              : Semantics(
                  key: ValueKey(reaction),
                  liveRegion: true,
                  label: 'Local reaction $reaction',
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xEF17120B),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFFD36B)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          reaction!,
                          key: const Key('local_reaction_toast'),
                          style: const TextStyle(fontSize: 34),
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

class MatchReactionPicker extends StatelessWidget {
  const MatchReactionPicker({super.key, required this.onReaction});

  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Emoji reactions · On this device',
              style: TextStyle(
                color: Color(0xFFFFD36B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reaction in localMatchReactions)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton(
                      key: Key('quick_reaction_$reaction'),
                      tooltip: 'Send $reaction reaction locally',
                      onPressed: () => onReaction(reaction),
                      icon: Text(
                        reaction,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
