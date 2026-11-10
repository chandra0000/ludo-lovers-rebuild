import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium ivory-and-gold die.
///
/// The game engine remains the source of truth for [value]. While [isRolling]
/// is true, this widget animates the die and briefly cycles its visible pips;
/// it never generates or changes the result itself.
class LuxuryAnimatedDice extends StatefulWidget {
  const LuxuryAnimatedDice({
    super.key,
    required this.value,
    required this.isRolling,
    required this.canRoll,
    required this.onTap,
    this.onRollCompleted,
    this.size = 72,
  }) : assert(value >= 1 && value <= 6);

  /// The authoritative result supplied by the game engine.
  final int value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback onTap;
  final VoidCallback? onRollCompleted;
  final double size;

  @override
  State<LuxuryAnimatedDice> createState() => _LuxuryAnimatedDiceState();
}

class _LuxuryAnimatedDiceState extends State<LuxuryAnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rollController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(covariant LuxuryAnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRolling && !oldWidget.isRolling) {
      HapticFeedback.mediumImpact();
      _startRoll();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _rollController.stop();
      _rollController.value = 0;
    }
  }

  void _startRoll() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isRolling) {
          widget.onRollCompleted?.call();
        }
      });
      return;
    }

    _rollController.forward(from: 0).then((_) {
      if (mounted && widget.isRolling) {
        widget.onRollCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hitTargetSize = math.max(widget.size, 48.0);

    return Semantics(
      button: true,
      enabled: widget.canRoll && !widget.isRolling,
      label: widget.isRolling
          ? 'Dice rolling'
          : 'Dice shows ${widget.value}. ${widget.canRoll ? 'Tap to roll' : 'Not your turn'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.canRoll && !widget.isRolling ? widget.onTap : null,
        child: SizedBox(
          width: hitTargetSize,
          height: hitTargetSize,
          child: Center(
            child: AnimatedBuilder(
              animation: _rollController,
              builder: (context, child) {
                final animating = widget.isRolling &&
                    _rollController.status == AnimationStatus.forward;
                final progress = Curves.easeOutCubic.transform(
                  _rollController.value,
                );
                // Derive the temporary face from animation progress rather
                // than Random() in build, keeping frames reproducible.
                final rollingValue =
                    ((_rollController.value * 37).floor() % 6) + 1;
                final displayedValue =
                    animating ? rollingValue : widget.value;
                final bounce = animating
                    ? _bounceScale(_rollController.value)
                    : 1.0;

                return Transform.scale(
                  scale: bounce,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(animating ? progress * 4 * math.pi : 0)
                      ..rotateY(animating ? progress * 6 * math.pi : 0)
                      ..rotateZ(
                        animating
                            ? math.sin(_rollController.value * math.pi * 2) *
                                0.2
                            : 0,
                      ),
                    child: _LuxuryDiceFace(
                      size: widget.size,
                      value: displayedValue,
                      isGilded: widget.canRoll,
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

  double _bounceScale(double progress) {
    if (progress < 0.3) {
      return 1 + (progress / 0.3) * 0.35;
    }
    if (progress < 0.7) {
      return 1.35 - ((progress - 0.3) / 0.4) * 0.5;
    }
    return 0.85 + ((progress - 0.7) / 0.3) * 0.15;
  }
}

class _LuxuryDiceFace extends StatelessWidget {
  const _LuxuryDiceFace({
    required this.size,
    required this.value,
    required this.isGilded,
  });

  final double size;
  final int value;
  final bool isGilded;

  static const _gold = Color(0xFFFFD36B);

  @override
  Widget build(BuildContext context) {
    final pipSize = size * 0.18;

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
            Color(0xFFF3EFE0),
            Color(0xFFDED8C7),
          ],
        ),
        border: Border.all(
          color: isGilded ? _gold : const Color(0xFFB0A48A),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          if (isGilded)
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.48),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          const BoxShadow(
            color: Colors.white70,
            blurRadius: 2,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: _DicePips(value: value, pipSize: pipSize),
      ),
    );
  }
}

class _DicePips extends StatelessWidget {
  const _DicePips({required this.value, required this.pipSize});

  final int value;
  final double pipSize;

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

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var column = 0; column < 3; column++)
                _Pip(active: active.contains(row * 3 + column), size: pipSize),
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
    if (!active) {
      return SizedBox(width: size, height: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF37474F), Color(0xFF080A0D)],
        ),
        border: Border.all(color: const Color(0xFFB57C1E), width: 1.1),
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
