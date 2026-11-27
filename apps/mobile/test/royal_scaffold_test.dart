import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/match/player_slot_resolver.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/team_up_policy.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final mode in MatchMode.values) {
    test('visual slots and scheduled turns stay independent for ${mode.name}',
        () {
      var game = ModeRegistry.create(
        mode,
        playerCount: mode == MatchMode.classic ? 2 : 4,
        allowInternal: true,
      );
      final profiles = MatchPlayerProfile.local(aiPlayers: {PlayerColor.green});
      final slots = PlayerSlotResolver.resolve(game, profiles);
      expect(slots.map((s) => s.profile.color), [
        PlayerColor.orange,
        PlayerColor.green,
        PlayerColor.blue,
        PlayerColor.magenta,
      ]);
      expect(
        slots.where((s) => s.participating).length,
        mode == MatchMode.classic ? 2 : 4,
      );
      expect(slots.every((s) => s.team == null), mode != MatchMode.teamUp);
      if (mode == MatchMode.teamUp) {
        expect(slots[0].team, TeamUpTeam.a);
        expect(slots[3].team, TeamUpTeam.a);
        expect(slots[1].team, TeamUpTeam.b);
        expect(slots[2].team, TeamUpTeam.b);
      }
      final order = mode == MatchMode.classic
          ? [PlayerColor.orange, PlayerColor.magenta]
          : PlayerColor.turnOrder;
      for (final color in [...order, ...order]) {
        expect(game.activePlayer, color);
        game = game.roll(2).passTurn();
      }
    });
  }
  testWidgets('inactive slots are placeholders and AI identity uses a robot',
      (tester) async {
    final game = ModeRegistry.create(
      MatchMode.classic,
      playerCount: 2,
      allowInternal: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: game,
          aiPlayers: const {PlayerColor.magenta},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('EMPTY / WAITING'), findsNWidgets(2));
    expect(find.byKey(const Key('robot_magenta')), findsOneWidget);
    expect(find.textContaining('BOT · AI'), findsOneWidget);
    expect(find.text('TEAM-UP'), findsNothing);
    expect(find.text('Roll dice'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets(
      'calibration can still hide dynamic profiles without moving board geometry',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MatchScreen(showDynamicProfiles: false)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_orange')), findsNothing);
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'robot thinking indicator reflects the actual active AI presentation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: LudoGame.fromProgress(
            activePlayer: PlayerColor.green,
            pawnProgress: const {},
          ),
          aiPlayers: const {PlayerColor.green},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('ai_thinking_green')), findsOneWidget);
    expect(find.textContaining('AI thinking'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
