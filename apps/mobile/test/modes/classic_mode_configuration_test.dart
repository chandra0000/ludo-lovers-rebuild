import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/features/setup/mode_selection_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('default remains compatibility and unfinished modes stay unavailable',
      () {
    expect(
      ModeRegistry.create(MatchMode.compatibility).ruleProfile,
      LudoRuleProfile.currentV1,
    );
    expect(() => ModeRegistry.create(MatchMode.classic), throwsStateError);
    expect(
      () => ModeRegistry.create(MatchMode.quick),
      throwsStateError,
    );
    expect(
      () => ModeRegistry.create(MatchMode.teamUp),
      throwsStateError,
    );
  });
  for (final count in [2, 3, 4]) {
    test('$count Classic seats rotate canonically without absent actors', () {
      var game = ModeRegistry.create(
        MatchMode.classic,
        playerCount: count,
        allowInternal: true,
      );
      final order = switch (count) {
        2 => [PlayerColor.orange, PlayerColor.magenta],
        3 => [PlayerColor.orange, PlayerColor.green, PlayerColor.magenta],
        _ => PlayerColor.turnOrder,
      };
      expect(game.players.map((p) => p.color).toList(), order);
      final session = MatchSession.local(matchId: 'seats', game: game);
      expect(session.actorIds.keys, unorderedEquals(order));
      for (var turn = 0; turn < count * 2; turn++) {
        expect(game.activePlayer, order[turn % count]);
        game = game
            .roll(2, commandId: 'roll-$turn')
            .passTurn(commandId: 'pass-$turn');
      }
      final restored = LudoGame.decodeSnapshot(game.encodeSnapshot());
      expect(restored.encodeSnapshot(), game.encodeSnapshot());
      expect(restored.configuration.activePlayers, order);
      expect(
        () => restored.configuration.activePlayers.add(PlayerColor.blue),
        throwsUnsupportedError,
      );
      final stale = session.execute(
        const RollDiceCommand(
          matchId: 'seats',
          actorId: 'local-seat-blue',
          expectedStateVersion: 0,
          commandId: 'wrong',
          value: 6,
        ),
      );
      expect(stale.accepted, isFalse);
    });
    test(
        '$count-seat Classic seeded full match finishes and replays deterministically',
        () {
      LudoGame simulate() {
        var game = ModeRegistry.create(
          MatchMode.classic,
          playerCount: count,
          allowInternal: true,
        );
        final random = Random(20261117 + count);
        var commands = 0;
        while (game.winner == null && commands < 20000) {
          game = game.roll(
            random.nextInt(6) + 1,
            expectedStateVersion: game.stateVersion,
            commandId: 'c${commands++}',
          );
          if (game.diceValue == null) continue;
          final pawn =
              const SeededLudoAi().choosePawn(game, seed: game.stateVersion);
          game = pawn == null
              ? game.passTurn(
                  expectedStateVersion: game.stateVersion,
                  commandId: 'c${commands++}',
                )
              : game.movePawn(
                  pawn,
                  expectedStateVersion: game.stateVersion,
                  commandId: 'c${commands++}',
                );
        }
        expect(game.winner, isNotNull);
        expect(
          game.players.singleWhere((p) => p.color == game.winner).hasWon,
          isTrue,
        );
        return game;
      }

      final first = simulate();
      final second = simulate();
      expect(second.encodeSnapshot(), first.encodeSnapshot());
      expect(
        LudoGame.decodeSnapshot(first.encodeSnapshot()).encodeSnapshot(),
        first.encodeSnapshot(),
      );
    });
  }
  test('v4 rejects mode/seat corruption; v3 retains its original profile', () {
    final game = ModeRegistry.create(
      MatchMode.classic,
      playerCount: 2,
      allowInternal: true,
    );
    final corrupt = game.toSnapshot();
    corrupt['configuration'] = {
      'id': 'classic',
      'version': 1,
      'activePlayers': ['orange', 'blue'],
    };
    expect(() => LudoGame.fromSnapshot(corrupt), throwsFormatException);
    final legacy = LudoGame.initial().toSnapshot()
      ..['schemaVersion'] = 3
      ..remove('configuration');
    final restored = LudoGame.fromSnapshot(legacy);
    expect(restored.ruleProfile, LudoRuleProfile.currentV1);
    expect(restored.configuration.activePlayers, PlayerColor.turnOrder);
  });
  testWidgets('public mode cards keep preview modes visibly locked',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ModeSelectionScreen()));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('mode_compatibility')))
          .onPressed,
      isNotNull,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('mode_classic')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('mode_classic')))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('COMING SOON'), findsWidgets);
  });
  testWidgets(
      'internal Classic setup starts two real seats and restart retains them',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: GameSetupScreen(
          mode: MatchMode.classic,
          allowInternalModes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode_player_count')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 players').last);
    await tester.pumpAndSettle();
    final start = find.byKey(const Key('start_local_match'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsOneWidget);
    expect(find.byKey(const Key('pawn_green_0')), findsNothing);
    expect(find.byKey(const Key('pawn_blue_0')), findsNothing);
    expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('more_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart match'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESTART'));
    await tester.pumpAndSettle();
    final saved = (await const SavedMatchStore().load())!;
    expect(
      saved.game.configuration.activePlayers,
      [PlayerColor.orange, PlayerColor.magenta],
    );
    expect(saved.game.ruleProfile, LudoRuleProfile.classicV1);
    expect(tester.takeException(), isNull);
  });
}
