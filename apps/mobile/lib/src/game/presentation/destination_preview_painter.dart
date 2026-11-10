import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DestinationPreviewType { standard, capture, safeCoexist }

class DestinationPreviewPainter extends CustomPainter {
  const DestinationPreviewPainter({
    required this.targetCenter,
    required this.cellSize,
    required this.playerColor,
    required this.previewType,
    required this.animationProgress,
  });

  final Offset targetCenter;
  final double cellSize;
  final Color playerColor;
  final DestinationPreviewType previewType;
  final double animationProgress;

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant DestinationPreviewPainter oldDelegate) =>
      oldDelegate.targetCenter != targetCenter ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.playerColor != playerColor ||
      oldDelegate.previewType != previewType ||
      oldDelegate.animationProgress != animationProgress;
}
