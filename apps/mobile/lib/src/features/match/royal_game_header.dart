import 'package:flutter/material.dart';
import 'royal_crown.dart';

class RoyalGameHeader extends StatelessWidget {
  const RoyalGameHeader({
    super.key,
    required this.onExit,
    required this.trailing,
  });
  final VoidCallback onExit;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Stack(
        key: const Key('match_top_rail'),
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('exit_match'),
              tooltip: 'Exit match',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: onExit,
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFFFFE3A0),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 48, height: 48, child: trailing),
          ),
        ],
      );
}

/// The approved mark occupies the same central axis as the bottom dice arena.
class RoyalBrandMark extends StatelessWidget {
  const RoyalBrandMark({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x55D9AD55), blurRadius: 24),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipOval(
                child: Image.asset(
                  'assets/images/branding/ludo_lovers_icon.webp',
                  key: const Key('match_brand_mark'),
                  cacheWidth: 216,
                  semanticLabel: 'Ludo Lovers',
                ),
              ),
            ),
            const Positioned(
              top: -5,
              right: 0,
              left: 0,
              child: IgnorePointer(
                child: Center(child: RoyalCrown(size: 16)),
              ),
            ),
          ],
        ),
      );
}
