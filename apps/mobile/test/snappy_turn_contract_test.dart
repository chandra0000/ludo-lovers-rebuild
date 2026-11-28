import 'package:flutter/services.dart';
import 'package:ludo_lovers/src/features/match/match_feedback.dart';
import 'package:ludo_lovers/src/game/domain/feedback_preferences.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'support/wait_for_board_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/features/game/domain/ludo_turn_engine.dart';
import 'package:ludo_lovers/features/game/presentation/widgets/beveled_3d_dice.dart';
import 'package:ludo_lovers/src/features/match/match_command_controller.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

MatchCommandController controller(LudoGame game) => MatchCommandController(
      MatchSession.local(matchId: 'snappy-contract', game: game),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('new local v2 is explicit and old snapshots retain their rules', () {
    final old = LudoGame.initial();
    final current = ModeRegistry.create(MatchMode.compatibility);
    expect(current.ruleProfile, LudoRuleProfile.currentV2);
    expect(
      LudoGame.decodeSnapshot(old.encodeSnapshot()).ruleProfile,
      LudoRuleProfile.currentV1,
    );
    expect(
      LudoGame.decodeSnapshot(current.encodeSnapshot()).ruleProfile,
      LudoRuleProfile.currentV2,
    );
    expect(
      ModeRegistry.create(MatchMode.classic).ruleProfile,
      LudoRuleProfile.classicV1,
    );
  });
  test(
      'equivalent yard choice is deterministic; distinct track choices stay direct',
      () {
    final yard = controller(LudoGame.initial());
    addTearDown(yard.dispose);
    expect(
      yard.execute(yard.buildRoll(value: 6, isAi: false, aiSeed: 1)).accepted,
      isTrue,
    );
    expect(yard.turns.settleDice(), 0);
    final track = controller(
      LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [0, 10, -1, -1],
        },
      ),
    );
    addTearDown(track.dispose);
    track.execute(track.buildRoll(value: 2, isAi: false, aiSeed: 1));
    expect(track.turns.settleDice(), isNull);
    expect(track.turns.snapshot.phase, LudoTurnPhase.awaitingBoardTap);
  });
  test('third six retains its accepted face/player until presentation settles',
      () {
    final game = LudoGame.initial(ruleProfile: LudoRuleProfile.currentV2)
        .roll(6)
        .movePawn(0)
        .roll(6)
        .movePawn(0);
    final c = controller(game);
    addTearDown(c.dispose);
    final cmd = c.buildRoll(value: 6, isAi: false, aiSeed: 1);
    final result = c.execute(cmd);
    expect(result.events.whereType<DiceRolled>().single.value, 6);
    expect(result.events.whereType<ConsecutiveSixPenalty>(), hasLength(1));
    expect(c.game.activePlayer, PlayerColor.green);
    expect(c.turns.snapshot.presentedPlayer, PlayerColor.orange);
    expect(c.turns.snapshot.phase, LudoTurnPhase.rolling);
    final unchanged = c.turns.snapshot;
    expect(c.execute(cmd).accepted, isFalse);
    expect(identical(c.turns.snapshot, unchanged), isTrue);
    c.turns.settleDice();
    expect(c.turns.snapshot.phase, LudoTurnPhase.awaitingRoll);
    expect(c.turns.snapshot.presentedPlayer, PlayerColor.green);
  });
  test('every active seat rolls before a no-move pass; no silent skip', () {
    final c = controller(
      ModeRegistry.create(MatchMode.compatibility, playerCount: 2),
    );
    addTearDown(c.dispose);
    expect(c.execute(c.buildPass()).accepted, isFalse);
    for (final player in [PlayerColor.orange, PlayerColor.magenta]) {
      expect(c.game.activePlayer, player);
      final result = c.execute(c.buildRoll(value: 1, isAi: false, aiSeed: 1));
      expect(result.events.whereType<DiceRolled>().single.player, player);
      c.turns.settleDice();
      expect(c.turns.snapshot.phase, LudoTurnPhase.noMovesPass);
      expect(c.execute(c.buildPass()).accepted, isTrue);
      c.turns.completeMovement();
    }
    expect(c.game.activePlayer, PlayerColor.orange);
    expect(c.game.stateVersion, 4);
  });
  test('all eight authoritative safe cells protect opposing stacks in v2', () {
    expect(BoardGeometry.safeTrackCells, hasLength(8));
    for (final cell in BoardGeometry.safeTrackCells) {
      final green = (cell - 13 + 52) % 52;
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.currentV2,
        pawnProgress: {
          PlayerColor.orange: [cell == 0 ? -1 : cell - 1, -1, -1, -1],
          PlayerColor.green: [green, green, -1, -1],
        },
      );
      final moved = game.roll(cell == 0 ? 6 : 1).movePawn(0);
      expect(moved.players[1].pawnProgress.take(2), [green, green]);
      expect(moved.events.whereType<PawnCaptured>(), isEmpty);
    }
  });
  test('v2 finish bonus preserves old v1 finish behavior', () {
    for (final profile in [
      LudoRuleProfile.currentV1,
      LudoRuleProfile.currentV2,
    ]) {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: profile,
        pawnProgress: {
          PlayerColor.orange: [55, -1, -1, -1],
        },
      ).roll(1).movePawn(0);
      expect(
        game.activePlayer,
        profile.version == 2 ? PlayerColor.orange : PlayerColor.green,
      );
    }
  });
  testWidgets('420ms dice completes once on the next scheduler tick',
      (tester) async {
    int? value;
    var id = 0, calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) => LuxuryDiceButton(
            targetValue: value,
            rollId: id,
            canRoll: value == null,
            isWaitingForRoll: value == null,
            onRollRequested: () => update(() {
              value = 6;
              id++;
            }),
            onAnimationComplete: () {
              calls++;
              expect(value, 6);
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('luxury_dice_gesture')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 419));
    expect(calls, 0);
    // Flutter interpolation isDone uses time > duration, so sample the next tick.
    await tester.pump(const Duration(milliseconds: 2));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(find.text('6'), findsNothing);
  });
  testWidgets('match roles remain frozen across caller mutation and rebuild',
      (tester) async {
    final roles = <PlayerColor>{PlayerColor.green};
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(key: const Key('same-match'), aiPlayers: roles),
      ),
    );
    await waitForBoardArtwork(tester);
    await tester.pumpAndSettle();
    roles.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(key: const Key('same-match'), aiPlayers: roles),
      ),
    );
    await waitForBoardArtwork(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('robot_green')), findsOneWidget);
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    final saved = (await const SavedMatchStore().load())!;
    expect(saved.game.stateVersion, greaterThanOrEqualTo(1));
    expect(saved.aiPlayers, {PlayerColor.green});
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('accepted move phases are ordered and never mutate the command version',
      () {
    final c = controller(
      LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [0, -1, -1, -1],
        },
      ),
    );
    addTearDown(c.dispose);
    final phases = <LudoTurnPhase>[];
    c.turns.addListener((s) => phases.add(s.phase), fireImmediately: false);
    c.execute(c.buildRoll(value: 2, isAi: false, aiSeed: 1));
    c.turns.settleDice();
    c.execute(c.buildMove(0));
    c.turns.completeMovement();
    expect(phases, [
      LudoTurnPhase.rolling,
      LudoTurnPhase.evaluatingMoves,
      LudoTurnPhase.awaitingBoardTap,
      LudoTurnPhase.animatingPawn,
      LudoTurnPhase.resolveTileEvent,
      LudoTurnPhase.checkVictory,
      LudoTurnPhase.nextTurn,
      LudoTurnPhase.awaitingRoll,
    ]);
    expect(c.game.stateVersion, 2);
  });
  test('v2 unsafe capture alone emits capture bonus and returns victim to yard',
      () {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      ruleProfile: LudoRuleProfile.currentV2,
      pawnProgress: {
        PlayerColor.orange: [0, -1, -1, -1],
        PlayerColor.green: [42, -1, -1, -1],
      },
    ).roll(3).movePawn(0);
    expect(game.events.whereType<PawnCaptured>(), hasLength(1));
    expect(game.events.whereType<ExtraTurnGranted>(), hasLength(1));
    expect(game.players[1].pawnProgress.first, -1);
    expect(game.activePlayer, PlayerColor.orange);
  });

  testWidgets('default tactile cues use light, selection and heavy impacts',
      (tester) async {
    final methods = <Object?>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') methods.add(call.arguments);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final feedback = MatchFeedback();
    for (final cue in [
      MatchFeedbackCue.roll,
      MatchFeedbackCue.hop,
      MatchFeedbackCue.capture,
      MatchFeedbackCue.finish,
    ]) {
      await feedback.play(cue, const FeedbackPreferences());
    }
    expect(methods, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
    await feedback.dispose();
  });
  for (var selected = 0; selected < 4; selected++) {
    testWidgets(
        'compact four-pawn fan selects exact pawn $selected without a sheet',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [5, 5, 5, 5],
        },
      ).roll(2, commandId: 'fan-roll');
      await tester
          .pumpWidget(MaterialApp(home: MatchScreen(initialGame: game)));
      await waitForBoardArtwork(tester);
      await tester.pumpAndSettle();
      final centers = [
        for (var i = 0; i < 4; i++)
          tester.getCenter(find.byKey(Key('pawn_orange_$i'))),
      ];
      for (var i = 1; i < 4; i++) {
        expect(centers[i].dx - centers[i - 1].dx, closeTo(16, .1));
      }
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(find.byKey(Key('pawn_orange_$selected')));
      await tester.pumpAndSettle();
      final moved = (await const SavedMatchStore().load())!.game;
      expect(moved.stateVersion, 2);
      expect(moved.appliedCommandIds, hasLength(2));
      expect(
        moved.players.first.pawnProgress,
        [for (var i = 0; i < 4; i++) i == selected ? 7 : 5],
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
