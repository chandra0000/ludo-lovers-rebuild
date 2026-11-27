import '../../theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Presentation-only result action. The engine supplies the outcome and the
/// owner creates the next MatchSession; this widget never decides a winner.
class MatchResultPresentation extends StatelessWidget {
  const MatchResultPresentation({super.key, required this.onRematch});

  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xF2160B28),
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: const Text('Victory!', style: AppTypography.heading),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRematch,
                child: const Text('PLAY AGAIN'),
              ),
            ],
          ),
        ),
      );
}
