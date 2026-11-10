import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/presentation/animated_dice.dart';
import 'package:ludo_lovers/src/app.dart';

void main() {
  testWidgets('renders the home screen on the first frame', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.byKey(const Key('brand_logo')), findsOneWidget);
    expect(find.byKey(const Key('start_local_match')), findsOneWidget);
  });

  testWidgets('opens a local match from the home screen', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    await tester.tap(find.byKey(const Key('start_local_match')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_green_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_blue_0')), findsOneWidget);
  });
  
  testWidgets('plays a deterministic release and turn-change sequence', (tester) async {
    final rolls = <int>[6, 2];
    var rollIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(rollDice: () => rolls[rollIndex++]),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedDice>(find.byKey(const Key('animated_dice'))).value, 6);

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedDice>(find.byKey(const Key('animated_dice'))).value, 2);

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
  });
  
  testWidgets('offers a chooser when multiple legal pawns share a cell', (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, 0, -1, -1],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game, rollDice: () => 2),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE A PAWN'), findsOneWidget);
    expect(find.text('Pawn 1'), findsOneWidget);
    expect(find.text('Pawn 2'), findsOneWidget);

    await tester.tap(find.text('Pawn 2'));
    await tester.pumpAndSettle();
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
  });
}

