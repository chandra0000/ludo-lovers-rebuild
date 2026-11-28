import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight metallic-gold cube with an authoritative result.
///
/// [targetValue] and [rollId] are supplied by the match controller. Increment
/// [rollId] for every accepted roll, even when the new result equals the
/// previous result. The widget never generates or changes the dice outcome.
class LuxuryDiceButton extends StatefulWidget {
  const LuxuryDiceButton({
    super.key,
    required this.targetValue,
    required this.rollId,
    required this.canRoll,
    required this.isWaitingForRoll,
    required this.onRollRequested,
    this.onAnimationComplete,
    this.size = 72,
    this.visualScale = 1,
  })  : assert(targetValue == null || (targetValue >= 1 && targetValue <= 6)),
        assert(visualScale > 0 && visualScale <= 1);

  /// Authoritative engine result, or null while no result is active.
  final int? targetValue;

  /// Monotonically increasing identifier for each accepted roll.
  /// It distinguishes consecutive rolls that produce the same face value.
  final int rollId;

  final bool canRoll;
  final bool isWaitingForRoll;
  final VoidCallback onRollRequested;
  final VoidCallback? onAnimationComplete;
  final double size;

  /// Scales only the painted cube; the semantic and gesture region stays [size].
  final double visualScale;

  @override
  State<LuxuryDiceButton> createState() => _LuxuryDiceButtonState();
}

class _LuxuryDiceButtonState extends State<LuxuryDiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addStatusListener(_handleAnimationStatus);

  bool _isAnimating = false;
  bool _requestPending = false;
  int _activeRollId = 0;
  int? _completedRollId;
  int? _settledValue;
  int _callbackGeneration = 0;

  @override
  void initState() {
    super.initState();
    // A restored game state is displayed immediately; it is not a new roll.
    _activeRollId = widget.rollId;
    _completedRollId = widget.rollId;
    _settledValue = widget.targetValue;
  }

  @override
  void didUpdateWidget(covariant LuxuryDiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.canRoll || !widget.isWaitingForRoll) {
      _requestPending = false;
    }

    if (widget.rollId != oldWidget.rollId) {
      _requestPending = false;
      _activeRollId = widget.rollId;
      _cancelCurrentAnimation();
      _completedRollId = null;
      _settledValue = widget.targetValue;
      if (widget.targetValue != null) {
        _startTumble(widget.rollId);
      }
      return;
    }

    if (widget.targetValue == null) {
      if (oldWidget.targetValue != null || _isAnimating) {
        _cancelCurrentAnimation();
        _settledValue = null;
        _requestPending = false;
      }
      return;
    }

    // Supports an asynchronous controller: rollId may arrive before the
    // authoritative server result. Animate once that result becomes available.
    if (oldWidget.targetValue == null &&
        widget.targetValue != null &&
        _completedRollId != widget.rollId) {
      _startTumble(widget.rollId);
      return;
    }

    // If an in-flight authoritative result is corrected, restart the same
    // roll's animation. A completed roll is simply updated without re-callback.
    if (widget.targetValue != oldWidget.targetValue && _isAnimating) {
      _startTumble(widget.rollId);
    } else if (!_isAnimating) {
      _settledValue = widget.targetValue;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if ((MediaQuery.maybeOf(context)?.disableAnimations ?? false) &&
        _isAnimating) {
      final rollId = _activeRollId;
      _cancelCurrentAnimation();
      final generation = _callbackGeneration;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _completeRoll(rollId, generation));
    }
  }

  void _cancelCurrentAnimation() {
    _callbackGeneration++;
    _controller.stop();
    _controller.value = 0;
    _isAnimating = false;
  }

  void _startTumble(int rollId) {
    if (rollId != _activeRollId || _completedRollId == rollId) return;

    _callbackGeneration++;
    final generation = _callbackGeneration;
    _controller.stop();
    _controller.value = 0;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _isAnimating = false;
      _settledValue = widget.targetValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeRoll(rollId, generation);
      });
      return;
    }

    _isAnimating = true;
    _settledValue = null;
    _controller.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isAnimating) {
      _completeRoll(_activeRollId, _callbackGeneration);
    }
  }

  void _completeRoll(int rollId, int generation) {
    if (!mounted ||
        generation != _callbackGeneration ||
        rollId != widget.rollId ||
        rollId != _activeRollId ||
        widget.targetValue == null ||
        _completedRollId == rollId) {
      return;
    }

    _completedRollId = rollId;
    _isAnimating = false;
    _settledValue = widget.targetValue;
    _requestPending = false;

    // Settle the face before notifying the match coordinator. The generation
    // and completed-roll guards ensure this callback is delivered exactly once.
    setState(() {});
    widget.onAnimationComplete?.call();
  }

  void _handleTap() {
    if (_isAnimating ||
        _requestPending ||
        !widget.canRoll ||
        !widget.isWaitingForRoll) {
      return;
    }

    _requestPending = true;
    widget.onRollRequested();
  }

  @override
  void dispose() {
    _callbackGeneration++;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.canRoll &&
        widget.isWaitingForRoll &&
        !_isAnimating &&
        !_requestPending;
    final valueLabel = widget.targetValue == null
        ? 'not rolled'
        : widget.targetValue.toString();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: Semantics(
        key: const Key('luxury_dice_semantics'),
        label: _isAnimating ? 'Dice rolling' : 'Dice, value $valueLabel',
        hint: _isAnimating
            ? 'Wait for the dice result.'
            : interactive
                ? 'Double tap to roll the dice.'
                : widget.targetValue == null
                    ? 'Dice is unavailable right now.'
                    : 'Choose one of the highlighted movable pawns.',
        button: interactive,
        enabled: interactive,
        child: GestureDetector(
          key: const Key('luxury_dice_gesture'),
          behavior: HitTestBehavior.opaque,
          onTap: interactive ? _handleTap : null,
          child: SizedBox(
            width: math.max(widget.size, 48.0),
            height: math.max(widget.size, 48),
            child: TweenAnimationBuilder<double>(
              key: ValueKey((interactive, widget.rollId, _isAnimating)),
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              builder: (context, t, child) {
                final pulse = interactive ? .055 * math.sin(t * math.pi) : 0.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (interactive)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _SlotPulse(t)),
                        ),
                      ),
                    Transform.scale(scale: 1 + pulse, child: child),
                  ],
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final t = _controller.value;
                      final spinT = (t * 1.5).clamp(0.0, 1.0);
                      final landing = Curves.easeOutCubic.transform(spinT);
                      final turns = widget.rollId.isEven ? 2.0 : 3.0;
                      final target = _settledValue ?? widget.targetValue ?? 1;
                      final angles = _DiceCube.orientationFor(target);
                      final spin = _isAnimating
                          ? (1 - landing) * turns * 2 * math.pi
                          : 0.0;
                      final lift = _isAnimating
                          ? math.sin(math.pi * spinT) * widget.size * .22
                          : 0.0;
                      final anticipation = _isAnimating && t < .12
                          ? 1 - .07 * (t / .12)
                          : _isAnimating
                              ? .93 + .07 * ((t - .12) / .88)
                              : 1.0;
                      final settleT = ((t - 2 / 3) * 3).clamp(0.0, 1.0);
                      final settle = _isAnimating && t >= 2 / 3
                          ? .94 + .06 * Curves.easeOutBack.transform(settleT)
                          : 1.0;
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _GroundShadow(
                                  lift / (widget.size * .22),
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, -lift),
                            child: Transform.scale(
                              scale: anticipation * settle,
                              child: _DiceCube(
                                key: const Key('six_face_dice_cube'),
                                size: widget.size * widget.visualScale,
                                value: target,
                                isInteractive: interactive,
                                xAngle: angles.$1 + spin + .16,
                                yAngle: angles.$2 + spin * .83 - .20,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Six independently oriented faces share one rigid 3D transform.
/// Opposite faces sum to seven; the match engine supplies the settled value.
class _DiceCube extends StatelessWidget {
  const _DiceCube({
    super.key,
    required this.size,
    required this.value,
    required this.isInteractive,
    required this.xAngle,
    required this.yAngle,
  });

  final double size;
  final int value;
  final bool isInteractive;
  final double xAngle;
  final double yAngle;

  // Face normals: 1 front, 6 back, 3 right, 4 left, 2 top, 5 bottom.
  static (double, double) orientationFor(int face) => switch (face) {
        1 => (0, 0),
        6 => (0, math.pi),
        3 => (0, -math.pi / 2),
        4 => (0, math.pi / 2),
        2 => (-math.pi / 2, 0),
        5 => (math.pi / 2, 0),
        _ => (0, 0),
      };

  @override
  Widget build(BuildContext context) {
    final half = size / 2;
    final rotation = Matrix4.identity()
      ..rotateX(xAngle)
      ..rotateY(yAngle);
    final faces = <({int value, Matrix4 transform, double depth})>[];
    for (final face in <(int, double, double)>[
      (1, 0, 0),
      (6, 0, math.pi),
      (3, 0, math.pi / 2),
      (4, 0, -math.pi / 2),
      (2, math.pi / 2, 0),
      (5, -math.pi / 2, 0),
    ]) {
      final faceRotation = Matrix4.identity()
        ..rotateY(face.$3)
        ..rotateX(face.$2);
      final combined = rotation.clone()..multiply(faceRotation);
      // A face is only painted when its outward normal faces the camera.
      final normalZ = combined.storage[10];
      if (normalZ <= 0.001) continue;
      faces.add(
        (
          value: face.$1,
          transform: combined
            ..multiply(Matrix4.translationValues(0.0, 0.0, half)),
          depth: normalZ * half,
        ),
      );
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFE699), Color(0xFF9A6512)],
              ),
            ),
            child: SizedBox(width: size * .88, height: size * .88),
          ),
          for (final face in faces)
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0022)
                ..multiply(face.transform),
              child: _DiceFace(
                key: Key('dice_face_${face.value}'),
                size: size,
                value: face.value,
                isInteractive: isInteractive,
                light: .62 + .38 * (face.depth / half),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({
    super.key,
    required this.size,
    required this.value,
    required this.isInteractive,
    required this.light,
  });
  final double size;
  final int value;
  final bool isInteractive;
  final double light;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: BeveledDiceFacePainter(value: value, light: light),
        ),
      );
}

class BeveledDiceFacePainter extends CustomPainter {
  const BeveledDiceFacePainter({required this.value, required this.light});
  final int value;
  final double light;
  static const positions = <int, List<(int, int)>>{
    1: [(1, 1)],
    2: [(0, 0), (2, 2)],
    3: [(0, 0), (1, 1), (2, 2)],
    4: [(0, 0), (2, 0), (0, 2), (2, 2)],
    5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
    6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)],
  };
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 72;
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(18 * scale));
    final paint = Paint()..isAntiAlias = true;
    // Continuous metallic perimeter, with an inset sculpted face.
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF0B3), Color(0xFFD4A237), Color(0xFF7A520D)],
      stops: [0, .48, 1],
    ).createShader(rect);
    canvas.drawRRect(outer, paint);
    final innerRect = rect.deflate(3 * scale);
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF9C6714), const Color(0xFFFFE899), light)!,
        Color.lerp(const Color(0xFF81500C), const Color(0xFFE6B13E), light)!,
        const Color(0xFFBA8122),
      ],
      stops: const [0, .5, 1],
    ).createShader(innerRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(15 * scale)),
      paint,
    );
    paint
      ..shader = null
      ..color = const Color(0x99FFF0B3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale;
    canvas.drawRRect(outer.deflate(scale / 2), paint);
    paint.style = PaintingStyle.fill;
    for (final (x, y) in positions[value]!) {
      final center =
          Offset(size.width * (.28 + x * .22), size.height * (.28 + y * .22));
      final radius = 4.8 * scale;
      paint.color = const Color(0xFFFFE699);
      canvas.drawCircle(
        center + Offset(scale, scale),
        radius + .8 * scale,
        paint,
      );
      final pipRect = Rect.fromCircle(center: center, radius: radius);
      paint.shader = RadialGradient(
        center: const Alignment(-.5, -.5),
        colors: value == 1 || value == 6
            ? const [Color(0xFF26070B), Color(0xFF841C28), Color(0xFFCD7958)]
            : const [Color(0xFF070707), Color(0xFF28231A), Color(0xFF6D592F)],
      ).createShader(pipRect);
      canvas.drawCircle(center, radius, paint);
      paint
        ..shader = null
        ..color = Colors.black45
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * scale;
      canvas.drawArc(
        pipRect.deflate(.5 * scale),
        math.pi,
        math.pi,
        false,
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(BeveledDiceFacePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.light != light;
}

/// Public integration API: the caller supplies the accepted result and roll ID.
class Beveled3DDice extends StatelessWidget {
  const Beveled3DDice({
    super.key,
    required this.value,
    required this.rollId,
    required this.canRoll,
    required this.onRoll,
    required this.onRollComplete,
    this.size = 64,
  });
  final int? value;
  final int rollId;
  final bool canRoll;
  final VoidCallback onRoll;
  final ValueChanged<int> onRollComplete;
  final double size;
  @override
  Widget build(BuildContext context) => LuxuryDiceButton(
        targetValue: value,
        rollId: rollId,
        canRoll: canRoll,
        isWaitingForRoll: value == null,
        onRollRequested: onRoll,
        size: size,
        onAnimationComplete: () {
          final result = value;
          if (result != null) onRollComplete(result);
        },
      );
}

class _GroundShadow extends CustomPainter {
  const _GroundShadow(this.height);
  final double height;
  @override
  void paint(Canvas canvas, Size size) {
    final h = height.clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .88),
        width: size.width * (.78 - .22 * h),
        height: size.height * .14,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .42 - .18 * h)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 3 * h),
    );
  }

  @override
  bool shouldRepaint(_GroundShadow old) => old.height != height;
}

class _SlotPulse extends CustomPainter {
  const _SlotPulse(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect.deflate(2),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x00D9AD55),
            const Color(0xFFD9AD55)
                .withValues(alpha: .1 + .15 * math.sin(progress * math.pi)),
            const Color(0x00D9AD55),
          ],
          stops: const [
            .35,
            .8,
            1,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SlotPulse old) => old.progress != progress;
}
