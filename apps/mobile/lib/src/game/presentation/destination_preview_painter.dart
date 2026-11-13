import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum DestinationPreviewType { standard, capture, safeCoexist }

class DestinationPreviewPainter extends CustomPainter {
  const DestinationPreviewPainter({
    required this.targetCenter,
    this.routePoints = const <Offset>[],
    required this.cellSize,
    required this.playerColor,
    required this.previewType,
    required this.animationProgress,
  });

  final Offset targetCenter;
  final List<Offset> routePoints;
  final double cellSize;
  final Color playerColor;
  final DestinationPreviewType previewType;
  final double animationProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintRouteArrows(canvas);
    final radius = cellSize * .45;
    final breathe = (math.sin(animationProgress * 2 * math.pi) + 1) / 2;
    final highlight = previewType == DestinationPreviewType.capture
        ? const Color(0xFFFF1744)
        : previewType == DestinationPreviewType.safeCoexist
            ? const Color(0xFFFFD54F)
            : playerColor;

    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          highlight.withValues(alpha: .38 + breathe * .16),
          highlight.withValues(alpha: .10),
          highlight.withValues(alpha: 0),
        ],
        stops: const [0, .65, 1],
      ).createShader(
        Rect.fromCircle(center: targetCenter, radius: radius * 1.2),
      );
    canvas.drawCircle(targetCenter, radius * (.95 + breathe * .15), wash);

    canvas.save();
    canvas.translate(targetCenter.dx, targetCenter.dy);
    canvas.rotate(animationProgress * 2 * math.pi);
    final bracket = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        i * math.pi / 2,
        math.pi * .275,
        false,
        bracket,
      );
    }
    canvas.restore();

    if (previewType == DestinationPreviewType.capture) {
      canvas.drawCircle(
        targetCenter,
        radius * (.4 + breathe * .08),
        Paint()
          ..color = highlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      canvas.drawCircle(
        targetCenter,
        3,
        Paint()..color = Colors.white.withValues(alpha: .9),
      );
    }
  }

  /// Marching chevrons travel along the real sequence of route anchors.
  /// No straight-line shortcuts across the board or game-state mutation.
  void _paintRouteArrows(Canvas canvas) {
    if (routePoints.length < 2) return;
    final paint = Paint()
      ..color = playerColor.withValues(alpha: .84)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const arrowSpacing = 20.0;
    final phase = animationProgress * arrowSpacing;
    for (var i = 1; i < routePoints.length; i++) {
      final from = routePoints[i - 1];
      final to = routePoints[i];
      final delta = to - from;
      final length = delta.distance;
      if (length < 1) continue;
      final unit = delta / length;
      final normal = Offset(-unit.dy, unit.dx);
      for (var distance = 6.0 + phase;
          distance < length - 6;
          distance += arrowSpacing) {
        final tip = from + unit * distance;
        final tail = tip - unit * 7;
        final chevron = Path()
          ..moveTo((tail + normal * 4).dx, (tail + normal * 4).dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo((tail - normal * 4).dx, (tail - normal * 4).dy);
        canvas.drawPath(chevron, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DestinationPreviewPainter oldDelegate) =>
      !listEquals(oldDelegate.routePoints, routePoints) ||
      oldDelegate.targetCenter != targetCenter ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.playerColor != playerColor ||
      oldDelegate.previewType != previewType ||
      oldDelegate.animationProgress != animationProgress;
}
