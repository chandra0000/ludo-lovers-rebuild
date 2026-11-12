import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium ivory-and-gold dice presentation.
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
  }) : assert(targetValue == null || (targetValue >= 1 && targetValue <= 6));

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

  @override
  State<LuxuryDiceButton> createState() => _LuxuryDiceButtonState();
}

class _LuxuryDiceButtonState extends State<LuxuryDiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
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
    HapticFeedback.lightImpact();
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

    return Semantics(
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
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final landing = Curves.easeOutCubic.transform(t);
                final turns = widget.rollId.isEven ? 2.0 : 3.0;
                final target = _settledValue ?? widget.targetValue ?? 1;
                final angles = _DiceCube.orientationFor(target);
                final spin =
                    _isAnimating ? (1 - landing) * turns * 2 * math.pi : 0.0;
                final lift = _isAnimating
                    ? math.sin(math.pi * t) * widget.size * .22
                    : 0.0;
                return Transform.translate(
                  offset: Offset(0, -lift),
                  child: _DiceCube(
                    key: const Key('six_face_dice_cube'),
                    size: widget.size,
                    value: target,
                    isInteractive: interactive,
                    xAngle: angles.$1 + spin,
                    yAngle: angles.$2 + spin * .83,
                  ),
                );
              },
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
      faces.add((
        value: face.$1,
        transform: combined..multiply(Matrix4.translationValues(0.0, 0.0, half)),
        depth: normalZ,
      ),
    );
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size * .12,
            top: size * .18,
            child: Container(
              width: size * .88,
              height: size * .88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * .2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 16,
                    spreadRadius: 3,
                    offset: Offset(2, 10),
                  ),
                ],
              ),
            ),
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
  });

  final double size;
  final int value;
  final bool isInteractive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF6F3EA),
            Color(0xFFE2DCCB),
          ],
        ),
        border: Border.all(
          color:
              isInteractive ? const Color(0xFFFFD54F) : const Color(0xFFC7BEA9),
          width: 2.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
          if (isInteractive)
            const BoxShadow(
              color: Color(0x66FFB300),
              blurRadius: 14,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.16),
          child: _DicePips(value: value, size: size),
        ),
      ),
    );
  }
}

class _DicePips extends StatelessWidget {
  const _DicePips({required this.value, required this.size});

  final int value;
  final double size;

  static const _positions = <int, Set<int>>{
    1: {4},
    2: {0, 8},
    3: {0, 4, 8},
    4: {0, 2, 6, 8},
    5: {0, 2, 4, 6, 8},
    6: {0, 2, 3, 5, 6, 8},
  };

  @override
  Widget build(BuildContext context) {
    final active = _positions[value]!;
    final pipSize = size * 0.17;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var column = 0; column < 3; column++)
                _Pip(
                  active: active.contains(row * 3 + column),
                  size: pipSize,
                ),
            ],
          ),
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.active, required this.size});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!active) return SizedBox(width: size, height: size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF37474F), Color(0xFF080A0D)],
        ),
        border: Border.all(color: const Color(0xFFB57C1E), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 2,
            offset: Offset(0.5, 1),
          ),
          BoxShadow(
            color: Color(0x66FFFFFF),
            blurRadius: 1,
            offset: Offset(-0.5, -0.5),
          ),
        ],
      ),
    );
  }
}
