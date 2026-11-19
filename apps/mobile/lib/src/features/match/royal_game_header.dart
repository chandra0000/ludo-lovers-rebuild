import 'package:flutter/material.dart';
import 'royal_crown.dart';

class RoyalGameHeader extends StatelessWidget {
  const RoyalGameHeader({
    super.key,
    required this.onExit,
    required this.spacious,
    required this.trailing,
  });
  final VoidCallback onExit;
  final bool spacious;
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
          Container(
            width: spacious ? 72 : 44,
            height: spacious ? 72 : 44,
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
                Positioned(
                  top: -5,
                  right: 0,
                  left: 0,
                  child: IgnorePointer(
                    child: Center(child: RoyalCrown(size: spacious ? 16 : 12)),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 48, height: 48, child: trailing),
          ),
        ],
      );
}
