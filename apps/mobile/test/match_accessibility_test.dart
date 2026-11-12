import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';

void main() {
  testWidgets('dice exposes a useful action hint to screen readers',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MatchScreen()),
    );

    final dice = tester.widget<Semantics>(
      find.byKey(const Key('luxury_dice_semantics')),
    );
    expect(dice.properties.button, isTrue);
    expect(dice.properties.enabled, isTrue);
    expect(dice.properties.label, 'Dice, value not rolled');
    expect(dice.properties.hint, 'Double tap to roll the dice.');
  });

  testWidgets('movable pawns announce their position and available action',
      (tester) async {
    final game = LudoGame.initial().roll(6);
    await tester.pumpWidget(
      MaterialApp(home: MatchScreen(initialGame: game)),
    );

    final pawn = find
        .ancestor(
          of: find.byKey(const Key('pawn_orange_0')),
          matching: find.byType(Semantics),
        )
        .first;
    final semantics = tester.widget<Semantics>(pawn);

    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.label, 'orange pawn 1');
    expect(semantics.properties.value, 'In yard');
    expect(semantics.properties.hint, 'Double tap to move this pawn.');
  });
}
