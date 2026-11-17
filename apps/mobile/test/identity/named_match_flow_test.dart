import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('setup names survive gameplay, restart and home resume',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: GameSetupScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_player_names')));
    await tester.pump();
    final field = find.byKey(const Key('player_name_orange'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '  Zoë   王 ');
    final start = find.byKey(const Key('start_local_match'));
    await tester.scrollUntilVisible(
      start,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('Zoë 王'), findsOneWidget);
    await tester.tap(find.byKey(const Key('more_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart match'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESTART'));
    await tester.pumpAndSettle();
    expect(find.text('Zoë 王'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final saved = (await const SavedMatchStore().load())!;
    expect(saved.profiles.first.displayName, 'Zoë 王');
    expect(saved.profiles.first.playerId, 'local-orange');
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resume_saved_match')));
    await tester.pumpAndSettle();
    expect(find.text('Zoë 王'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('blank human names show validation and do not start a game',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameSetupScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_player_names')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('player_name_orange')), '  ');
    final start = find.byKey(const Key('start_local_match'));
    await tester.scrollUntilVisible(
      start,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('Enter a visible player name.'), findsOneWidget);
    expect(find.byType(MatchScreen), findsNothing);
  });
  testWidgets('winner presentation retains the entered name and color',
      (tester) async {
    final won = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [56, 56, 56, 55],
      },
    ).roll(1).movePawn(3);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: won,
          profiles:
              MatchPlayerProfile.local(names: {PlayerColor.orange: 'Zoë 王'}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Zoë 王 (ORANGE) WINS'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final count in [2, 3]) {
    testWidgets(
        '$count human names stay on fixed seats with remaining AI roles',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 873);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: GameSetupScreen()));
      await tester.pumpAndSettle();
      final picker = find.byKey(const Key('human_player_count'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('$count').last);
      await tester.pumpAndSettle();
      final start = find.byKey(const Key('start_ai_match'));
      await tester.scrollUntilVisible(
        start,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      final screen = tester.widget<MatchScreen>(find.byType(MatchScreen));
      expect(screen.aiPlayers, PlayerColor.turnOrder.skip(count).toSet());
      expect(screen.profiles!.where((p) => !p.isBot), hasLength(count));
      expect(screen.profiles!.map((p) => p.color), PlayerColor.turnOrder);
      expect(screen.profiles!.map((p) => p.playerId).toSet(), hasLength(4));
      expect(tester.takeException(), isNull);
    });
  }
}
