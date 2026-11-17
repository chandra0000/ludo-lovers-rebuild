import 'package:flutter/material.dart';

/// Presentation-only result action. The engine supplies the outcome and the
/// owner creates the next MatchSession; this widget never decides a winner.
class MatchResultPresentation extends StatelessWidget {
  const MatchResultPresentation({super.key, required this.onRematch});

  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) => Positioned(
        left: 150,
        top: 480,
        width: 276,
        height: 80,
        child: Center(
          child: FilledButton(
            onPressed: onRematch,
            child: const Text('PLAY AGAIN'),
          ),
        ),
      );
}
