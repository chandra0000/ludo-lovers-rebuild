import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/match/match_pawn_layer.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';

import 'support/wait_for_board_artwork.dart';

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
      final previousLayer =
          tester.widget<MatchPawnLayer>(find.byType(MatchPawnLayer));
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
      await waitForBoardArtwork(tester);
      final layer = tester.widget<MatchPawnLayer>(find.byType(MatchPawnLayer));
      expect(layer.key, isNot(previousLayer.key));
      expect(layer.beforeLanding, isNull);
      final positions = <Offset>{};
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          positions.add(expectPawnAt(tester, color, pawn, -1));
        }
      }
      expect(positions, hasLength(16));
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

  testWidgets('a capture stays visible until the attacking pawn lands',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, 10, -1, -1],
        PlayerColor.green: [42, -1, -1, -1],
      },
    ).roll(3);
    await launch(tester, MatchScreen(initialGame: game));
    await waitForBoardArtwork(tester);
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final committed = await saved();
    expect(
      committed.players
          .firstWhere((p) => p.color == PlayerColor.green)
          .pawnProgress
          .first,
      -1,
    );
    expectPawnAt(tester, PlayerColor.green, 0, 42);
    expect(find.text('CAPTURE! EXTRA TURN'), findsNothing);

    await tester.pumpAndSettle();
    expectPawnAt(tester, PlayerColor.orange, 0, 3);
    expectPawnAt(tester, PlayerColor.green, 0, -1);
    expect(find.text('CAPTURE! EXTRA TURN'), findsOneWidget);
  });

  testWidgets('changing an input AI set cannot change a running seat',
      (tester) async {
    final controls = <PlayerColor>{};
    final initial = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [6, -1, -1, -1],
      },
    );
    await launch(
      tester,
      MatchScreen(initialGame: initial, aiPlayers: controls),
    );
    await waitForBoardArtwork(tester);
    controls.add(PlayerColor.orange);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: initial, aiPlayers: controls),
      ),
    );
    await tester.pumpAndSettle();
    final dice = tester.widget<LuxuryDiceButton>(find.byType(LuxuryDiceButton));
    expect(dice.canRoll, isTrue);
    expect(
      tester.widget<MatchPawnLayer>(find.byType(MatchPawnLayer)).aiPlayers,
      isEmpty,
    );
    expect((await saved()).toSnapshot(), initial.toSnapshot());
    expectPawnAt(tester, PlayerColor.orange, 0, 6);
    expectPawnAt(tester, PlayerColor.orange, 1, -1);
  });

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

Offset expectPawnAt(
  WidgetTester tester,
  PlayerColor color,
  int pawn,
  int progress,
) {
  final canvas = tester.getRect(find.byKey(const Key('match_canvas')));
  final point = BoardGeometry.normalizedPosition(color, progress, pawn);
  final center = tester.getCenter(find.byKey(Key('pawn_${color.name}_$pawn')));
  expect(center.dx, closeTo(canvas.left + canvas.width * point.x, .01));
  expect(center.dy, closeTo(canvas.top + canvas.height * point.y, .01));
  return center;
}
