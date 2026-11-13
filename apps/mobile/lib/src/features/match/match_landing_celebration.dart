import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import 'match_move_presentation_plan.dart';

/// Purely visual effect emitted after an accepted movement animation ends.
/// Never changes MatchSession or delays the next authoritative turn.
class MatchLandingCelebration extends StatefulWidget {
  const MatchLandingCelebration({super.key, required this.plan});

  final MatchMovePresentationPlan plan;

  @override
  State<MatchLandingCelebration> createState() =>
      _MatchLandingCelebrationState();
}

class _MatchLandingCelebrationState extends State<MatchLandingCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = BoardGeometry.canvasPosition(
      BoardGeometry.normalizedPosition(
        widget.plan.player,
        widget.plan.endProgress,
        widget.plan.pawnIndex,
      ),
    );
    final isCapture = widget.plan.feedback?.contains('CAPTURE') ?? false;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Positioned(
      left: point.x - 50,
      top: point.y - 50,
      width: 100,
      height: 100,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = reduceMotion ? 1.0 : _controller.value;
              final radius = 12 + 34 * Curves.easeOutCubic.transform(t);
              final opacity = (1 - t).clamp(0.0, 1.0);
              return CustomPaint(
                key: const Key('pawn_landing_fx'),
                painter: _LandingPainter(
                  progress: t,
                  radius: radius,
                  opacity: opacity,
                  color: widget.plan.player.color,
                  isCapture: isCapture,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LandingPainter extends CustomPainter {
  const _LandingPainter({
    required this.progress,
    required this.radius,
    required this.opacity,
    required this.color,
    required this.isCapture,
  });

  final double progress;
  final double radius;
  final double opacity;
  final Color color;
  final bool isCapture;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Paint()
      ..color = color.withValues(alpha: opacity * .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress) + .5;
    canvas.drawCircle(center, radius, ring);
    if (!isCapture) return;
    final spark = Paint()
      ..color = const Color(0xFFFFD36B).withValues(alpha: opacity)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = 2 * math.pi * i / 8;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 2);
      final end = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 11);
      canvas.drawLine(start, end, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _LandingPainter old) =>
      old.progress != progress ||
      old.radius != radius ||
      old.opacity != opacity ||
      old.color != color ||
      old.isCapture != isCapture;
}
