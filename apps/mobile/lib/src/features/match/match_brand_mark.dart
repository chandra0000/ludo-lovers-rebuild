import 'package:flutter/material.dart';

/// The approved bundled logo is decorative; it never replaces the game board.
class MatchBrandMark extends StatelessWidget {
  const MatchBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 212,
      top: 4,
      width: 152,
      height: 120,
      child: IgnorePointer(
        child: Center(
          child: Image.asset(
            'assets/images/branding/ludo_lovers_icon.webp',
            key: const Key('match_brand_mark'),
            width: 116,
            height: 116,
            cacheWidth: 256,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'Ludo Lovers',
            errorBuilder: (context, error, stackTrace) => const Text(
              'LUDO LOVERS',
              style: TextStyle(
                color: Color(0xFFFFD36B),
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
