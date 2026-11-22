import 'package:flutter/material.dart';

/// Decoration stays inside its HUD region; accepted dice commands live elsewhere.
class RoyalDiceArena extends StatelessWidget {
  const RoyalDiceArena({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRect(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, .35),
              radius: .7,
              colors: [Color(0x38D9AD55), Color(0x0012121A)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x36D9AD55),
                  blurRadius: 28,
                  spreadRadius: -12,
                  offset: Offset(0, 15),
                ),
                BoxShadow(
                  color: Color(0x6612121A),
                  blurRadius: 24,
                  spreadRadius: -12,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
}
