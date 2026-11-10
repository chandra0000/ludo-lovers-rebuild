import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable, presentation-only rejection feedback for an interactive pawn.
class ShakeFeedbackWrapper extends StatefulWidget {
  const ShakeFeedbackWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<ShakeFeedbackWrapper> createState() => ShakeFeedbackWrapperState();
}

class ShakeFeedbackWrapperState extends State<ShakeFeedbackWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  void triggerShake() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final progress = _controller.value;
          final decay = 1 - progress;
          final offset = math.sin(progress * 6 * math.pi) * 4.5 * decay;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
      );
}
