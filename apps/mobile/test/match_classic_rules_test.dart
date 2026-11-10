import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets(
    'Classic blockade constrains the human move and hands the turn to AI',
    (tester) async {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, 10, -1, -1],
          // Green progress 44 maps to Orange's physical track cell 5.
          PlayerColor.green: [44, 44, -1, -1],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(
            initialGame: game,
            aiPlayers: const {PlayerColor.green},
            aiSeed: 2026,
            rollDice: () => 3,
          ),
        ),
      );

      final blockedPawn = find.byKey(const Key('pawn_orange_0'));
      final onlyLegalPawn = find.byKey(const Key('pawn_orange_1'));
      final blockedPawnBefore = tester.getCenter(blockedPawn);
      final legalPawnBefore = tester.getCenter(onlyLegalPawn);

      await tester.tap(find.byKey(const Key('roll_dice')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 610));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 1));

      // The engine exposes only pawn 1 as legal; the UI auto-moves that pawn.
      expect(find.text('GREEN · AI TURN'), findsOneWidget);
      // Observe the in-flight pawn hop without advancing far enough to schedule
      // the AI's next delayed roll; AI legality is covered in the domain test.

      expect(tester.getCenter(blockedPawn), blockedPawnBefore);
      expect(tester.getCenter(onlyLegalPawn), isNot(legalPawnBefore));
      expect(find.text('GREEN · AI TURN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
