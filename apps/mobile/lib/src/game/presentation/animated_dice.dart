import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A vector-rendered Ludo die. The game engine supplies the outcome.
class AnimatedDice extends StatefulWidget {
  const AnimatedDice({
    super.key,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.onRollStarted,
    this.onRollCompleted,
  });
  final int? value;
  final VoidCallback onTap;
  final bool enabled;
  final VoidCallback? onRollStarted;
  final VoidCallback? onRollCompleted;

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  bool _isAnimating = false;

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != oldWidget.value) {
      _revealRoll();
    }
  }

  Future<void> _revealRoll() async {
    _isAnimating = true;
    widget.onRollStarted?.call();
    await _controller.forward(from: 0);
    if (!mounted) return;
    setState(() => _isAnimating = false);
    widget.onRollCompleted?.call();
  }

  void _handleTap() {
    if (!widget.enabled || _isAnimating || widget.value != null) return;
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value ?? 1;
    return Semantics(
      button: true,
      enabled: widget.enabled && !_isAnimating && widget.value == null,
      label: widget.value == null
          ? 'Roll dice'
          : "Dice shows $value${_isAnimating ? ', rolling' : ''}",
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = Curves.easeOutBack.transform(
                _controller.value.clamp(0.0, 1.0),
              );
              final angle = (1 - progress) * math.pi * 2.6;
              final scale = 1 + math.sin(progress * math.pi) * .18;
              final face = _isAnimating
                  ? 1 + ((_controller.value * 17).floor() % 6)
                  : value;
              return Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    size: const Size(58, 58),
                    painter: _DiceFacePainter(value: face),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiceFacePainter extends CustomPainter {
  const _DiceFacePainter({required this.value});
  final int value;

  static const List<List<Offset>> _pips = <List<Offset>>[
    [],
    [Offset(.5, .5)],
    [Offset(.28, .28), Offset(.72, .72)],
    [Offset(.28, .28), Offset(.5, .5), Offset(.72, .72)],
    [Offset(.28, .28), Offset(.72, .28), Offset(.28, .72), Offset(.72, .72)],
    [Offset(.28, .28), Offset(.72, .28), Offset(.5, .5), Offset(.28, .72), Offset(.72, .72)],
    [Offset(.28, .24), Offset(.72, .24), Offset(.28, .5), Offset(.72, .5), Offset(.28, .76), Offset(.72, .76)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width * .2;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );
    canvas.drawRRect(
      shape.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final faceRect = rect.deflate(2);
    final face = RRect.fromRectAndRadius(
      faceRect,
      Radius.circular(radius),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6D9), Color(0xFFFFD36B), Color(0xFFD99A2B)],
        ).createShader(faceRect),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFF0BD),
    );
    final pipPaint = Paint()..color = const Color(0xFF21180C);
    for (final point in _pips[value.clamp(1, 6)]) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        size.width * .065,
        pipPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) =>
      oldDelegate.value != value;
}
