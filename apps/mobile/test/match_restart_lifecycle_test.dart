import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<LudoGame> saved() async =>
      (await const SavedMatchStore().load())!.game;
  Future<void> launch(WidgetTester tester, Widget match) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: match));
    await tester.pumpAndSettle();
  }

  for (final rematch in [false, true]) {
    testWidgets('Classic profile survives ${rematch ? 'rematch' : 'restart'}',
        (tester) async {
      final game = rematch
          ? LudoGame.fromProgress(
              ruleProfile: LudoRuleProfile.classicV1,
              activePlayer: PlayerColor.orange,
              pawnProgress: {
                PlayerColor.orange: [56, 56, 56, 55],
              },
            ).roll(1).movePawn(3)
          : LudoGame.initial(ruleProfile: LudoRuleProfile.classicV1);
      await launch(tester, MatchScreen(initialGame: game));
      if (rematch) {
        await tester.tap(find.text('PLAY AGAIN'));
      } else {
        await tester.tap(find.byKey(const Key('more_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Restart match'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('RESTART'));
      }
      await tester.pumpAndSettle();
      final reset = await saved();
      expect(reset.ruleProfile.id, 'classic');
      expect(reset.ruleProfile.version, 1);
      expect(reset.stateVersion, 0);
      expect(reset.winner, isNull);
      expect(
        reset.players.every((p) => p.pawnProgress.every((v) => v == -1)),
        isTrue,
      );
    });
  }

  testWidgets('stale roll callback cannot consume randomness while paused',
      (tester) async {
    var rolls = 0;
    await launch(
      tester,
      MatchScreen(
        rollDice: () {
          rolls++;
          return 6;
        },
      ),
    );
    final stale = tester
        .widget<LuxuryDiceButton>(find.byType(LuxuryDiceButton))
        .onRollRequested;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    stale();
    await tester.pump();
    expect(rolls, 0);
    expect((await saved()).stateVersion, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(rolls, 1);
    expect((await saved()).diceValue, 6);
  });
}
