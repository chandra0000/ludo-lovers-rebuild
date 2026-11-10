import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('Classic third-six penalty advances to an AI player', (tester) async {
    final beforeThirdSix = LudoGame.initial(
      ruleProfile: LudoRuleProfile.classicV1,
    )
        .roll(6)
        .movePawn(0)
        .roll(6)
        .movePawn(0);

    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: beforeThirdSix,
          aiPlayers: const {PlayerColor.green},
          aiSeed: 17,
          rollDice: () => 6,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump();

    expect(find.text('THREE SIXES — TURN PASSED'), findsOneWidget);
    expect(find.text('GREEN · AI TURN'), findsOneWidget);

    // The penalized roll has no dice result to animate. The AI must still
    // receive its turn and begin a fresh authoritative roll.
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();

    final dice = tester.widget<Semantics>(
      find.byKey(const Key('luxury_dice_semantics')),
    );
    expect(dice.properties.label, 'Dice rolling');
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored pending AI roll passes without getting stranded',
      (tester) async {
    final pendingAiTurn = LudoGame.initial().roll(2);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: pendingAiTurn,
          aiPlayers: const {PlayerColor.orange},
          aiSeed: 42,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
