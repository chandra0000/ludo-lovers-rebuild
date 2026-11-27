import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/setup/mode_selection_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final count in [2, 3]) {
    test('$count local seeded full matches finish deterministically', () {
      String simulate() {
        var game =
            ModeRegistry.create(MatchMode.compatibility, playerCount: count);
        final random = Random(20261127 + count);
        var command = 0;
        while (game.winner == null && command < 20000) {
          game =
              game.roll(random.nextInt(6) + 1, commandId: 'roll-${command++}');
          if (game.diceValue == null) continue;
          final pawn =
              const SeededLudoAi().choosePawn(game, seed: game.stateVersion);
          game = pawn == null
              ? game.passTurn(commandId: 'pass-${command++}')
              : game.movePawn(pawn, commandId: 'move-${command++}');
        }
        expect(game.winner, isNotNull);
        return game.encodeSnapshot();
      }

      expect(simulate(), simulate());
    });
    test('$count public local seats retain rules, turns and saved identity',
        () {
      var game =
          ModeRegistry.create(MatchMode.compatibility, playerCount: count);
      final seats = count == 2
          ? [PlayerColor.orange, PlayerColor.magenta]
          : [PlayerColor.orange, PlayerColor.green, PlayerColor.magenta];
      expect(game.configuration.version, 2);
      expect(game.ruleProfile, LudoRuleProfile.currentV1);
      expect(game.players.map((p) => p.color), seats);
      if (count == 2) {
        expect((seats.last.entryIndex - seats.first.entryIndex) % 52, 26);
      }
      var session = MatchSession.local(matchId: 'public-$count', game: game);
      for (var turn = 0; turn < count * 2; turn++) {
        expect(session.game.activePlayer, seats[turn % count]);
        final command = RollDiceCommand(
          matchId: session.matchId,
          actorId: session.actorIds[session.game.activePlayer]!,
          expectedStateVersion: session.game.stateVersion,
          commandId: 'roll-$turn',
          value: 2,
        );
        final roll = session.execute(command);
        expect(roll.accepted, isTrue);
        session = roll.session;
        expect(
          session.execute(command).rejectionReason,
          MatchCommandRejectionReason.duplicateCommand,
        );
        final pass = session.execute(
          PassTurnCommand(
            matchId: session.matchId,
            actorId: session.actorIds[session.game.activePlayer]!,
            expectedStateVersion: session.game.stateVersion,
            commandId: 'pass-$turn',
          ),
        );
        expect(pass.accepted, isTrue);
        session = pass.session;
      }
      game = session.game;
      final saved = SavedMatch(game: game, aiPlayers: {}, aiSeed: 17);
      final restored = SavedMatch.decode(saved.encode());
      expect(restored.game.encodeSnapshot(), game.encodeSnapshot());
      expect(restored.game.configuration.activePlayers, seats);
      expect(
        LudoGame.initial(
          ruleProfile: game.ruleProfile,
          configuration: game.configuration,
        ).configuration.toJson(),
        game.configuration.toJson(),
      );
    });

    testWidgets('$count local preset starts a public human match',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 873);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: ModeSelectionScreen()));
      await tester
          .tap(find.byKey(Key(count == 2 ? 'launch_duel' : 'launch_three')));
      await tester.pumpAndSettle();
      expect(find.byType(GameSetupScreen), findsOneWidget);
      final start = find.byKey(const Key('start_local_match'));
      await tester.scrollUntilVisible(
        start,
        140,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(MatchScreen), findsOneWidget);
      final saved = (await const SavedMatchStore().load())!;
      expect(saved.game.configuration.activePlayers, hasLength(count));
      expect(saved.aiPlayers, isEmpty);
      expect(find.byKey(const Key('pawn_blue_0')), findsNothing);
      if (count == 2) {
        expect(find.byKey(const Key('pawn_green_0')), findsNothing);
        expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart match'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RESTART'));
      await tester.pumpAndSettle();
      final restarted = (await const SavedMatchStore().load())!;
      expect(
        restarted.game.configuration.toJson(),
        saved.game.configuration.toJson(),
      );
      expect(restarted.game.stateVersion, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  test('old four-seat saves and preview profiles keep their versions', () {
    expect(MatchConfiguration.compatibility.version, 1);
    expect(
      MatchConfiguration.fromJson(MatchConfiguration.compatibility.toJson())
          .activePlayers,
      PlayerColor.turnOrder,
    );
    expect(
      () => MatchConfiguration.fromJson({
        'id': 'local-current',
        'version': 1,
        'activePlayers': ['orange', 'magenta'],
      }),
      throwsFormatException,
    );
    expect(() => ModeRegistry.create(MatchMode.classic), throwsStateError);
    expect(() => ModeRegistry.create(MatchMode.quick), throwsStateError);
    expect(() => ModeRegistry.create(MatchMode.teamUp), throwsStateError);
    expect(
      () => MatchConfiguration.fromJson({
        'id': 'local-current',
        'version': 2,
        'activePlayers': ['orange', 'green'],
      }),
      throwsFormatException,
    );
    expect(
      () => MatchConfiguration.fromJson({
        'id': 'classic',
        'version': 2,
        'activePlayers': ['orange', 'magenta'],
      }),
      throwsFormatException,
    );
  });
}
