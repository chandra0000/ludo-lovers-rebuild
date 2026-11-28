import 'package:flutter/material.dart';
import '../../../../src/game/domain/player_color.dart';
import '../../../../src/game/presentation/player_color_theme.dart';

/// Four original vector portraits, stable by seat and independent of turn state.
class SeatAvatar extends StatelessWidget {
  const SeatAvatar({super.key, required this.player});
  final PlayerColor player;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _Portrait(player),
          child: const SizedBox.expand(),
        ),
      );
}

class _Portrait extends CustomPainter {
  const _Portrait(this.player);
  final PlayerColor player;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final i = PlayerColor.turnOrder.indexOf(player);
    final skin = [
      const Color(0xFFB97442),
      const Color(0xFF71452E),
      const Color(0xFFFFCFAB),
      const Color(0xFFE6A579),
    ][i];
    final hair = [
      const Color(0xFF211411),
      const Color(0xFF100D14),
      const Color(0xFF302023),
      const Color(0xFFB86E27),
    ][i];
    final p = Paint()..isAntiAlias = true;
    p.shader = RadialGradient(
      center: const Alignment(0, -.5),
      colors: [
        player.color.withValues(alpha: .45),
        const Color(0xFF10121F),
      ],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), p);
    p
      ..shader = null
      ..color = hair;
    if (i == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 15, 56, 77),
          const Radius.circular(26),
        ),
        p,
      );
    }
    p.color = player.color;
    canvas.drawOval(const Rect.fromLTWH(10, 72, 80, 65), p);
    p.color = const Color(0xFFD9AD55);
    canvas.drawPath(
      Path()
        ..moveTo(32, 77)
        ..lineTo(50, 97)
        ..lineTo(68, 77)
        ..lineTo(61, 73)
        ..lineTo(50, 84)
        ..lineTo(39, 73)
        ..close(),
      p,
    );
    p.color = skin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(41, 60, 18, 23),
        const Radius.circular(7),
      ),
      p,
    );
    canvas.drawOval(const Rect.fromLTWH(24, 19, 52, 57), p);
    p.color = hair;
    if (i == 0) {
      canvas.drawPath(
        Path()
          ..moveTo(24, 39)
          ..lineTo(25, 18)
          ..quadraticBezierTo(45, 0, 73, 19)
          ..lineTo(76, 38)
          ..lineTo(63, 24)
          ..lineTo(34, 30)
          ..close(),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(29, 57)
          ..quadraticBezierTo(49, 91, 71, 57)
          ..lineTo(65, 70)
          ..quadraticBezierTo(50, 82, 35, 69)
          ..close(),
        p,
      );
    } else if (i == 1) {
      for (var k = 0; k < 5; k++) {
        canvas.drawCircle(Offset(28 + k * 11, 21 - (k % 2) * 4), 10, p);
      }
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(23, 43)
          ..lineTo(26, 20)
          ..quadraticBezierTo(50, 2, 75, 25)
          ..lineTo(76, 43)
          ..quadraticBezierTo(62, 17, 51, 29)
          ..quadraticBezierTo(35, 37, 23, 43),
        p,
      );
    }
    p.color = const Color(0xFFFFF4DF);
    for (final x in [39.0, 61.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 45), width: 11, height: 7),
        p,
      );
    }
    p.color = const Color(0xFF17121B);
    for (final x in [40.0, 60.0]) {
      canvas.drawCircle(Offset(x, 45), 2.7, p);
    }
    if (i == 1) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFE3A0);
      for (final x in [38.0, 62.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 45), width: 20, height: 14),
            const Radius.circular(5),
          ),
          p,
        );
      }
      canvas.drawLine(const Offset(48, 45), const Offset(52, 45), p);
    }
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF70352C)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(41, 56, 18, 10), 0, 3.14, false, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Portrait old) => old.player != player;
}
