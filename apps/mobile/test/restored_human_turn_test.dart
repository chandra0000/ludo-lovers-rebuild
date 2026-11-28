import 'support/wait_for_board_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<LudoGame> savedGame() async =>
      (await const SavedMatchStore().load())!.game;

  testWidgets('restored unplayable human roll passes once without rerolling',
      (tester) async {
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: LudoGame.initial().roll(2, commandId: 'accepted-roll'),
          rollDice: () {
            rolls++;
            return 6;
          },
        ),
      ),
    );
    await waitForBoardArtwork(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 651));
    await tester.pump();
    final passed = await savedGame();
    expect(passed.activePlayer, PlayerColor.green);
    expect(passed.stateVersion, 2);
    expect(passed.diceValue, isNull);
    expect(passed.appliedCommandIds, contains('accepted-roll'));
    expect(rolls, 0);
    await tester.pump(const Duration(seconds: 2));
    expect((await savedGame()).encodeSnapshot(), passed.encodeSnapshot());
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored single legal human move completes once after resume',
      (tester) async {
    final pending = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, -1, -1, -1],
      },
    ).roll(3, commandId: 'accepted-roll');
    await tester
        .pumpWidget(MaterialApp(home: MatchScreen(initialGame: pending)));
    await waitForBoardArtwork(tester);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect((await savedGame()).stateVersion, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump(const Duration(seconds: 1));
    final moved = await savedGame();
    expect(moved.stateVersion, 2);
    expect(moved.players.first.pawnProgress[0], 3);
    expect(moved.activePlayer, PlayerColor.green);
    expect(moved.diceValue, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect((await savedGame()).encodeSnapshot(), moved.encodeSnapshot());
    expect(tester.takeException(), isNull);
  });
}
