import 'package:flutter/material.dart';

/// A small translucent, glass-finish Ludo cone. This is presentation only:
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
      child: CustomPaint(
        painter: _GlassyConePainter(
          color: color,
          isCurrentPlayer: isCurrentPlayer,
          isMovable: isMovable,
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
        ..color = Colors.black.withValues(alpha: .42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    if (isCurrentPlayer || isMovable) {
      canvas.drawOval(
        baseRect.inflate(w * (isMovable ? .22 : .12)),
        Paint()
          ..color = (isMovable ? const Color(0xFFFFD700) : color)
              .withValues(alpha: isMovable ? .42 : .25)
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

    final body = Path()
      ..moveTo(w * .5, h * .07)
      ..cubicTo(w * .43, h * .07, w * .37, h * .14, w * .35, h * .23)
      ..lineTo(w * .12, h * .72)
      ..cubicTo(w * .04, h * .87, w * .16, h * .98, w * .32, h * .98)
      ..lineTo(w * .68, h * .98)
      ..cubicTo(w * .84, h * .98, w * .96, h * .87, w * .88, h * .72)
      ..lineTo(w * .65, h * .23)
      ..cubicTo(w * .63, h * .14, w * .57, h * .07, w * .5, h * .07)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .82)!.withValues(alpha: .98),
            Color.lerp(color, Colors.white, .34)!.withValues(alpha: .96),
            color.withValues(alpha: .94),
            Color.lerp(color, Colors.black, .48)!.withValues(alpha: .98),
          ],
          stops: const [0, .22, .62, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // A narrow shaded facet gives the cone a rounded, dimensional silhouette.
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
        ..strokeWidth = isMovable ? 1.8 : 1.0
        ..color = isMovable
            ? const Color(0xFFFFF1A8)
            : Colors.white.withValues(alpha: .82),
    );

    // Curved specular streak creates the glass/plastic highlight.
    final shine = Path()
      ..moveTo(w * .43, h * .17)
      ..cubicTo(w * .32, h * .25, w * .25, h * .52, w * .22, h * .68);
    canvas.drawPath(
      shine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * .105
        ..color = Colors.white.withValues(alpha: .62),
    );
    final rimLight = Path()
      ..moveTo(w * .66, h * .21)
      ..quadraticBezierTo(w * .71, h * .4, w * .8, h * .68);
    canvas.drawPath(
      rimLight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * .035
        ..color = Colors.white.withValues(alpha: .3),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .49, h * .13),
        width: w * .13,
        height: h * .055,
      ),
      Paint()..color = Colors.white.withValues(alpha: .9),
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
