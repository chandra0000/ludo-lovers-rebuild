import 'package:flutter/material.dart';

/// Small decorative crown; the approved logo image remains untouched.
class RoyalCrown extends StatelessWidget {
  const RoyalCrown({super.key, this.size = 16});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _CrownPainter()),
        ),
      );
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .2)
      ..lineTo(size.width * .25, size.height * .45)
      ..lineTo(size.width * .5, 0)
      ..lineTo(size.width * .75, size.height * .45)
      ..lineTo(size.width, size.height * .2)
      ..lineTo(size.width * .85, size.height * .85)
      ..lineTo(size.width * .15, size.height * .85)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE3A0));
    canvas.drawLine(
      Offset(size.width * .15, size.height),
      Offset(size.width * .85, size.height),
      Paint()
        ..color = const Color(0xFFD9AD55)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}
