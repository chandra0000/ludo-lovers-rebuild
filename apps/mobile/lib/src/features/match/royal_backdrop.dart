import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Static, cached royal lighting. No timers, blur filters or hit-test surfaces.
class RoyalBackdrop extends StatelessWidget {
  const RoyalBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  key: Key('royal_backdrop'),
                  child: CustomPaint(painter: _RoyalBackdropPainter()),
                ),
              ),
            ),
          ),
          child,
        ],
      );
}

class _RoyalBackdropPainter extends CustomPainter {
  const _RoyalBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241237), Color(0xFF101329), Color(0xFF090C19)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.05),
          radius: .72,
          colors: [Color(0x24D9AD55), Color(0x0012121A)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.85),
          radius: .65,
          colors: [Color(0x30D9AD55), Color(0x00D9AD55)],
        ).createShader(rect),
    );
    // Deterministic ambient bokeh; static even when reduced motion is disabled.
    for (var i = 0; i < 14; i++) {
      final center = Offset(
        size.width * ((i * 37 % 97) / 97),
        size.height * ((i * 61 % 89) / 89),
      );
      final radius = 3.0 + i % 4 * 2;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE3A0).withValues(alpha: .035 + i % 3 * .008),
              const Color(0x00D9AD55),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
    final stroke = Paint()
      ..color = const Color(0x5CD9AD55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    final extent = math.min(64.0, size.width * .16);
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      canvas.save();
      canvas.translate(corner.dx, corner.dy);
      canvas.scale(corner.dx == 0 ? 1 : -1, corner.dy == 0 ? 1 : -1);
      final path = Path()
        ..moveTo(8, extent)
        ..cubicTo(8, 20, 20, 8, extent, 8)
        ..moveTo(14, extent * .8)
        ..cubicTo(14, 27, 25, 14, extent * .8, 14)
        ..moveTo(18, 30)
        ..cubicTo(18, 14, 39, 16, 31, 26)
        ..cubicTo(24, 34, 14, 24, 24, 21);
      canvas.drawPath(path, stroke);
      canvas.drawCircle(
        const Offset(14, 14),
        2,
        Paint()..color = const Color(0x66FFE3A0),
      );
      canvas.restore();
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: .9,
          colors: [Colors.transparent, Color(0x80040710)],
          stops: [.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RoyalBackdropPainter oldDelegate) => false;
}
