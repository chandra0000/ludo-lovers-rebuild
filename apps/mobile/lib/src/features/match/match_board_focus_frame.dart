import 'package:flutter/material.dart';

/// Exterior-only halo around the existing approved board artwork.
/// Nothing may paint over the board image, including blur and shadows.
class MatchBoardFocusFrame extends StatelessWidget {
  const MatchBoardFocusFrame({super.key});

  static const Rect artworkRect = Rect.fromLTWH(
    15 / 864 * 576,
    307 / 1536 * 1024,
    835 / 864 * 576,
    851 / 1536 * 1024,
  );

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          key: Key('match_board_focus_frame'),
          painter: _ExteriorBoardHaloPainter(),
        ),
      ),
    );
  }
}

class _ExteriorBoardHaloPainter extends CustomPainter {
  const _ExteriorBoardHaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final board = MatchBoardFocusFrame.artworkRect;
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(board),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      RRect.fromRectAndRadius(board.inflate(3), const Radius.circular(8)),
      Paint()
        ..color = const Color(0x662B9DFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board.inflate(2), const Radius.circular(7)),
      Paint()
        ..color = const Color(0xAAFFD36B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExteriorBoardHaloPainter oldDelegate) => false;
}
