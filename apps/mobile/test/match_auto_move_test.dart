import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('single legal pawn moves after a 350 ms anticipation delay',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, -1, -1, -1],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game, rollDice: () => 3),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    // Establish the dice ticker's start frame before advancing its duration.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 610));
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 349));
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple legal pawns still require player selection',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, 10, -1, -1],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game, rollDice: () => 2),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump(const Duration(milliseconds: 610));

    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
    expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_orange_1')), findsOneWidget);
    // Multiple legal moves require choosing WHICH pawn, not tapping it twice.
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
