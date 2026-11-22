import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';

/// Selection is a presentation command; legality is supplied by MatchSession.
Future<void> showPawnChooser(
  BuildContext context,
  List<int> legal,
  ValueChanged<int> onPawn,
) async {
  final selected = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF171320),
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: const Text('Choose a pawn', style: AppTypography.heading),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a legal pawn. Board stacks use the same pawn numbers.',
            ),
            for (var pawn = 0; pawn < 4; pawn++)
              Semantics(
                label:
                    'Pawn ${pawn + 1}, ${legal.contains(pawn) ? "legal move" : "no legal move"}',
                child: ListTile(
                  key: Key('pawn_choice_$pawn'),
                  minTileHeight: 56,
                  enabled: legal.contains(pawn),
                  leading: Icon(
                    legal.contains(pawn) ? Icons.adjust : Icons.block,
                  ),
                  title: Text(
                    'Pawn ${pawn + 1}',
                    style: AppTypography.playerName,
                  ),
                  subtitle: Text(
                    legal.contains(pawn) ? 'Legal move' : 'Unavailable',
                  ),
                  onTap: legal.contains(pawn)
                      ? () => Navigator.pop(context, pawn)
                      : null,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
  if (context.mounted && selected != null) onPawn(selected);
}
