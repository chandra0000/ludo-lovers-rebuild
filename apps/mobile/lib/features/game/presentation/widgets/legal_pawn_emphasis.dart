import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Finite emphasis avoids a perpetual ticker while a human considers a move.
class LegalPawnEmphasis extends StatelessWidget {
  const LegalPawnEmphasis({
    super.key,
    required this.movable,
    required this.reducedMotion,
    required this.child,
    this.badge,
    this.canvasScale = 1,
  });
  final bool movable, reducedMotion;
  final int? badge;
  final double canvasScale;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey((movable, reducedMotion)),
        tween: Tween(begin: 0, end: 1),
        duration: movable && !reducedMotion
            ? const Duration(milliseconds: 900)
            : Duration.zero,
        builder: (_, t, child) {
          final breath = movable && !reducedMotion
              ? math.pow(math.sin(t * math.pi * 3), 2).toDouble()
              : 0.0;
          return Transform.scale(
            scale: 1 + .12 * breath,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (movable)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD36B),
                            width: 1 + breath,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x66D9AD55),
                              blurRadius: 3 + 3 * breath,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                child!,
                if (badge != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF211626),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(
                            '$badge',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 9 / canvasScale,
                              color: const Color(0xFFFFE3A0),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        child: child,
      );
}
