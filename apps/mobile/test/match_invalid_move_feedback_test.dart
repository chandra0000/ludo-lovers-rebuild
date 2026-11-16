import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('tapping a blocked pawn explains the Classic blockade',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      ruleProfile: LudoRuleProfile.classicV1,
      pawnProgress: {
        // Keep two legal choices so this tests feedback during pawn selection,
        // rather than an unplayable restored roll that must now auto-pass.
        PlayerColor.orange: [3, 10, 20, -1],
        PlayerColor.green: [44, 44, -1, -1],
      },
    ).roll(4);

    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pump();

    expect(find.text('PATH BLOCKED BY A PAWN BLOCKADE'), findsOneWidget);
    expect(find.byKey(const Key('invalid_move_feedback')), findsOneWidget);
  });
}
