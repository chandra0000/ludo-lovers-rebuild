import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches and survives repeated local-match navigation', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await tester.pumpWidget(const LudoLoversApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await pumpUntilSettled(tester);
    expect(find.text('WELCOME TO LUDO LOVERS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('skip_onboarding')));
    await pumpUntilSettled(tester);

    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);

    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.tap(find.byKey(const Key('open_game_setup')));
      await pumpUntilSettled(tester);
      await tester.tap(find.byKey(const Key('start_local_match')));
      await pumpUntilSettled(tester);

      expect(find.byKey(const Key('match_canvas')), findsOneWidget);
      expect(find.byKey(const Key('roll_dice')), findsOneWidget);
      expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
      expect(find.byKey(const Key('pawn_green_0')), findsOneWidget);
      expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
      expect(find.byKey(const Key('pawn_blue_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('exit_match')));
      await pumpUntilSettled(tester);

      // Match exits to Game Setup; explicitly return home before the next cycle.
      expect(find.byKey(const Key('start_local_match')), findsOneWidget);
      await tester.pageBack();
      await pumpUntilSettled(tester);
      expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
    }
  });

  testWidgets('completes a deterministic dice roll and pawn movement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          aiSeed: 42,
          rollDice: () => 6,
        ),
      ),
    );
    await pumpUntilSettled(tester);

    // 1. The real match canvas, board artwork and dice control are rendered.
    expect(find.byKey(const Key('match_canvas')), findsOneWidget);
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(find.byKey(const Key('turn_status')), findsOneWidget);

    final pawn = find.byKey(const Key('pawn_orange_0'));
    expect(pawn, findsOneWidget);
    final startingPosition = tester.getCenter(pawn);

    // 2. Roll a deterministic six and allow the 600 ms dice tumble to finish.
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump(const Duration(milliseconds: 700));
    await pumpUntilSettled(tester);

    // 3. Confirm the dice settled on the engine-provided result and the turn
    // status remains available after the animation callback.
    expect(
      tester.widget<Semantics>(
        find.byKey(const Key('luxury_dice_semantics')),
      ).properties.label,
      'Dice, value 6',
    );
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);

    // 4. Release the first legal orange pawn and wait for its hop animation.
    await tester.tap(pawn);
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.tap(pawn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await pumpUntilSettled(tester);

    expect(pawn, findsOneWidget);
    expect(tester.getCenter(pawn), isNot(startingPosition));
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
  });
}


/// Pumps animations in bounded increments so a never-ending ticker cannot
/// hold the Android integration runner indefinitely.
Future<void> pumpUntilSettled(
  WidgetTester tester, {
  int maxPumps = 100,
}) async {
  for (var pump = 0; pump < maxPumps; pump++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.binding.transientCallbackCount == 0) {
      return;
    }
  }
  throw TestFailure(
    'Widget tree did not settle within ${maxPumps * 100} ms.',
  );
}
