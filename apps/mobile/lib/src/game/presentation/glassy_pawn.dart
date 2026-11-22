import 'package:flutter/material.dart';

/// A sculpted glass-finish Ludo pawn with a rounded crown and raised foot. This is presentation only:
/// ownership, position, selection and legal-move state come from the game.
class GlassyPawn extends StatelessWidget {
  const GlassyPawn({
    super.key,
    required this.color,
    this.size = 30,
    this.isCurrentPlayer = false,
    this.isMovable = false,
  });

  final Color color;
  final double size;
  final bool isCurrentPlayer;
  final bool isMovable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.18,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GlassyConePainter(
            color: color,
            isCurrentPlayer: isCurrentPlayer,
            isMovable: isMovable,
          ),
        ),
      ),
    );
  }
}

class _GlassyConePainter extends CustomPainter {
  const _GlassyConePainter({
    required this.color,
    required this.isCurrentPlayer,
    required this.isMovable,
  });

  final Color color;
  final bool isCurrentPlayer;
  final bool isMovable;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * .88;
    final baseRect = Rect.fromCenter(
      center: Offset(w * .5, baseY),
      width: w * .94,
      height: h * .25,
    );

    // Soft grounding shadow and active-player halo.
    canvas.drawOval(
      baseRect.shift(Offset(0, h * .035)),
      Paint()
        ..color = Colors.black.withValues(alpha: .60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    if (isCurrentPlayer || isMovable) {
      canvas.drawOval(
        baseRect.inflate(w * (isMovable ? .22 : .12)),
        Paint()
          ..color = (isMovable ? const Color(0xFFFFD700) : color)
              .withValues(alpha: isMovable ? .24 : .13)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            w * (isMovable ? .28 : .2),
          ),
      );
    }

    // Contact occlusion keeps the piece grounded without changing its
    // geometry or introducing textures / additional GPU allocations.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, baseY + h * .055),
        width: w * .7,
        height: h * .095,
      ),
      Paint()..color = Colors.black.withValues(alpha: .28),
    );

    // A neck, tapered shoulder and broad foot remain inside the original box.
    // Board anchors and touch targets are independent of this silhouette.
    final body = Path()
      ..moveTo(w * .39, h * .34)
      ..quadraticBezierTo(w * .38, h * .48, w * .24, h * .65)
      ..cubicTo(w * .17, h * .74, w * .10, h * .77, w * .12, h * .86)
      ..quadraticBezierTo(w * .18, h * .97, w * .5, h * .98)
      ..quadraticBezierTo(w * .82, h * .97, w * .88, h * .86)
      ..cubicTo(w * .90, h * .77, w * .83, h * .74, w * .76, h * .65)
      ..quadraticBezierTo(w * .62, h * .48, w * .61, h * .34)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .65)!.withValues(alpha: .98),
            Color.lerp(color, Colors.white, .28)!.withValues(alpha: .96),
            color.withValues(alpha: .94),
            Color.lerp(color, Colors.black, .48)!.withValues(alpha: .98),
          ],
          stops: const [0, .22, .62, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // A narrow shaded facet gives the body a rounded, dimensional silhouette.
    // It is clipped to the existing pawn path so the approved board anchors,
    // hit regions and visual extents remain exactly unchanged.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTWH(w * .56, h * .07, w * .34, h * .87),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Color.lerp(color, Colors.black, .65)!.withValues(alpha: .34),
          ],
        ).createShader(Rect.fromLTWH(w * .56, 0, w * .34, h)),
    );
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xDD160B28),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMovable ? 1.8 : 1.0
        ..color = isMovable
            ? const Color(0xFFFFF1A8)
            : Colors.white.withValues(alpha: .82),
    );

    // Controlled directional reflections emphasize the neck and tapered body.
    final shine = Path()
      ..moveTo(w * .41, h * .44)
      ..cubicTo(w * .36, h * .53, w * .28, h * .65, w * .23, h * .75);
    canvas.drawPath(
      shine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * .105
        ..color = Colors.white.withValues(alpha: .62),
    );
    final rimLight = Path()
      ..moveTo(w * .62, h * .46)
      ..quadraticBezierTo(w * .70, h * .62, w * .79, h * .76);
    canvas.drawPath(
      rimLight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * .035
        ..color = Colors.white.withValues(alpha: .3),
    );
    final neck = Rect.fromCenter(
      center: Offset(w * .5, h * .395),
      width: w * .34,
      height: h * .085,
    );
    canvas.drawOval(
      neck,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, .60)!,
            color,
            Color.lerp(color, Colors.black, .55)!,
          ],
        ).createShader(neck),
    );

    final crown = Rect.fromLTWH(w * .28, h * .045, w * .44, h * .36);
    canvas.drawOval(
      crown,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.55),
          radius: 1.1,
          colors: [
            Color.lerp(color, Colors.white, .88)!,
            Color.lerp(color, Colors.white, .18)!,
            Color.lerp(color, Colors.black, .58)!,
          ],
          stops: const [0, .46, 1],
        ).createShader(crown),
    );
    canvas.drawOval(
      crown,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .035
        ..color = isMovable
            ? const Color(0xFFFFE6A2)
            : Colors.white.withValues(alpha: .66),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .42, h * .135),
        width: w * .13,
        height: h * .055,
      ),
      Paint()..color = Colors.white.withValues(alpha: .88),
    );

    // The broad circular foot makes the piece read as a classic Ludo cone.
    canvas.drawOval(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, .58)!,
            color,
            Color.lerp(color, Colors.black, .42)!,
          ],
        ).createShader(baseRect),
    );
    // A thin upper rim and a softer lower edge read as a raised glass foot.
    canvas.drawArc(
      baseRect.deflate(w * .035),
      3.4,
      2.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .045
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .58),
    );
    canvas.drawOval(
      baseRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassyConePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isCurrentPlayer != isCurrentPlayer ||
      oldDelegate.isMovable != isMovable;
}
