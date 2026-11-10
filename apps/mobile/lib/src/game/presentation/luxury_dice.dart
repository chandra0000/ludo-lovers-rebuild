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
  static const List<List<int>> _tumblePatterns = [
    [3, 5, 2, 6, 1, 4, 2, 5, 3, 6, 4, 1],
    [2, 4, 1, 5, 6, 3, 4, 2, 5, 1, 6, 3],
    [5, 1, 6, 2, 4, 3, 1, 6, 2, 5, 3, 4],
    [4, 6, 3, 1, 5, 2, 6, 3, 1, 4, 2, 5],
  ];

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

  int _visibleFace() {
    if (!_isAnimating) {
      return _settledValue ?? widget.targetValue ?? 1;
    }

    final pattern = _tumblePatterns[widget.rollId % _tumblePatterns.length];
    final frame = (_controller.value * pattern.length)
        .floor()
        .clamp(0, pattern.length - 1)
        .toInt();
    return pattern[frame];
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
      label: _isAnimating
          ? 'Dice rolling'
          : 'Dice, value $valueLabel',
      button: true,
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
                final progress = Curves.easeOutCubic.transform(
                  _controller.value,
                );
                final face = _visibleFace();
                final bounce = !_isAnimating
                    ? 1.0
                    : _controller.value < 0.3
                        ? 1 + (_controller.value / 0.3) * 0.25
                        : _controller.value < 0.7
                            ? 1.25 -
                                ((_controller.value - 0.3) / 0.4) * 0.35
                            : 0.9 +
                                ((_controller.value - 0.7) / 0.3) * 0.1;

                return Transform.scale(
                  scale: bounce,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateX(_isAnimating ? progress * 4 * math.pi : 0)
                      ..rotateY(_isAnimating ? progress * 6 * math.pi : 0)
                      ..rotateZ(
                        _isAnimating
                            ? math.sin(_controller.value * math.pi * 2) * 0.15
                            : 0,
                      ),
                    child: _DiceFace(
                      size: widget.size,
                      value: face,
                      isInteractive: interactive,
                    ),
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

class _DiceFace extends StatelessWidget {
  const _DiceFace({
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
          color: isInteractive
              ? const Color(0xFFFFD54F)
              : const Color(0xFFC7BEA9),
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
