import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  LudoGame quick(List<int> progress) => LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {PlayerColor.orange: progress},
        ruleProfile: LudoRuleProfile.quickV1,
        configuration:
            MatchConfiguration.local(MatchMode.quick, playerCount: 2),
      );

  test('Quick is a distinct opt-in versioned profile with four yard pawns', () {
    final game = ModeRegistry.create(
      MatchMode.quick,
      playerCount: 2,
      allowInternal: true,
    );
    expect(game.ruleProfile.id, 'quick');
    expect(game.ruleProfile.version, 1);
    expect(game.configuration.finishTarget, 2);
    expect(
      game.players.every(
        (p) =>
            p.pawnProgress.length == 4 && p.pawnProgress.every((v) => v == -1),
      ),
      isTrue,
    );
    expect(() => ModeRegistry.create(MatchMode.quick), throwsStateError);
    expect(LudoGame.initial().ruleProfile, LudoRuleProfile.currentV1);
  });
  test('one finish continues; second finish wins immediately without bonus',
      () {
    final one = quick([55, -1, -1, -1]).roll(1).movePawn(0);
    expect(one.winner, isNull);
    expect(one.events.whereType<ExtraTurnGranted>(), hasLength(1));
    final won = quick([56, 55, -1, -1]).roll(1).movePawn(1);
    expect(won.winner, PlayerColor.orange);
    expect(won.currentPlayer.hasWon, isFalse);
    expect(won.events.whereType<GameCompleted>(), hasLength(1));
    expect(won.events.whereType<ExtraTurnGranted>(), isEmpty);
    expect(() => won.roll(6), throwsStateError);
    expect(
      LudoGame.decodeSnapshot(won.encodeSnapshot()).encodeSnapshot(),
      won.encodeSnapshot(),
    );
  });
  test(
      'Classic still requires all four; Quick snapshot retains pending result and IDs',
      () {
    final classic = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [56, 55, -1, -1],
      },
      ruleProfile: LudoRuleProfile.classicV1,
    ).roll(1).movePawn(1);
    expect(classic.winner, isNull);
    final pending = quick([56, 55, -1, -1]).roll(1, commandId: 'accepted');
    final saved = SavedMatch(game: pending, aiPlayers: const {}, aiSeed: 7);
    final restored = SavedMatch.decode(saved.encode()).game;
    expect(restored.configuration.mode, MatchMode.quick);
    expect(restored.encodeSnapshot(), pending.encodeSnapshot());
    expect(() => restored.movePawn(1, commandId: 'accepted'), throwsStateError);
    expect(
      () => restored.movePawn(1, expectedStateVersion: 0),
      throwsStateError,
    );
  });
  testWidgets('Quick result, rematch and restored configuration use live game',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final won = quick([56, 55, -1, -1]).roll(1).movePawn(1);
    await tester.pumpWidget(MaterialApp(home: MatchScreen(initialGame: won)));
    await tester.pumpAndSettle();
    expect(
      find.text('QUICK'),
      findsNothing,
    ); // Header is logo-only; mode stays in saved configuration.
    expect(find.text('ORANGE WINS'), findsOneWidget);
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pumpAndSettle();
    final reset = (await const SavedMatchStore().load())!.game;
    expect(reset.configuration.mode, MatchMode.quick);
    expect(
      reset.configuration.activePlayers,
      [PlayerColor.orange, PlayerColor.magenta],
    );
    expect(reset.winner, isNull);
    expect(reset.stateVersion, 0);
  });
  test('mode metadata cannot relabel Quick as compatibility', () {
    final snapshot =
        ModeRegistry.create(MatchMode.quick, allowInternal: true).toSnapshot();
    snapshot['configuration'] = MatchConfiguration.compatibility.toJson();
    expect(() => LudoGame.fromSnapshot(snapshot), throwsFormatException);
  });
}
