import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/team_up_policy.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/match/match_move_presentation_plan.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> frame(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  LudoGame team({
    PlayerColor active = PlayerColor.orange,
    Map<PlayerColor, List<int>> progress = const {},
    Map<int, TeamUpTeam> priority = const {},
  }) =>
      LudoGame.fromProgress(
        activePlayer: active,
        pawnProgress: progress,
        ruleProfile: LudoRuleProfile.teamUpV1,
        teamCapturePriority: priority,
        configuration: MatchConfiguration.local(MatchMode.teamUp),
      );
  testWidgets('public Team Up setup reaches the live team HUD', (tester) async {
    await frame(
      tester,
      const GameSetupScreen(
        mode: MatchMode.teamUp,
        allowInternalModes: false,
      ),
    );
    final start = find.byKey(const Key('start_local_match'));
    await tester.scrollUntilVisible(
      start,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('team_progress_a')), findsOneWidget);
    expect(find.byKey(const Key('team_progress_b')), findsOneWidget);
    expect(find.text('TEAM A · 0/8'), findsOneWidget);
    expect(find.text('TEAM B · 0/8'), findsOneWidget);
    expect(
      (await const SavedMatchStore().load())!.game.configuration.mode,
      MatchMode.teamUp,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('transferred turn and progress restore without another roll',
      (tester) async {
    final game = team(
      progress: {
        PlayerColor.orange: [56, 56, 56, 56],
      },
    );
    await const SavedMatchStore()
        .save(SavedMatch(game: game, aiPlayers: const {}, aiSeed: 3));
    await frame(tester, const HomeScreen(allowInternalModes: true));
    await tester.tap(find.byKey(const Key('resume_saved_match')));
    await tester.pumpAndSettle();
    expect(find.text('ORANGE → MAGENTA'), findsOneWidget);
    expect(find.text('TEAM A · 4/8'), findsOneWidget);
    expect(find.text('TEAM B · 0/8'), findsOneWidget);
    expect((await const SavedMatchStore().load())!.game.stateVersion, 0);
  });
  testWidgets('public build resumes an existing Team Up save', (tester) async {
    await const SavedMatchStore()
        .save(SavedMatch(game: team(), aiPlayers: const {}, aiSeed: 3));
    await frame(tester, const HomeScreen());
    final button = tester
        .widget<OutlinedButton>(find.byKey(const Key('resume_saved_match')));
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('resume_saved_match')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('team_progress_a')), findsOneWidget);
    expect(
      (await const SavedMatchStore().load())!.game.ruleProfile,
      LudoRuleProfile.teamUpV1,
    );
  });
  test('friendly loss is not projected as a capture celebration', () {
    final moved = team(
      active: PlayerColor.green,
      progress: {
        PlayerColor.orange: [5, -1, -1, -1],
        PlayerColor.green: [44, -1, -1, -1],
        PlayerColor.blue: [18, -1, -1, -1],
      },
      priority: {
        5: TeamUpTeam.a,
      },
    ).roll(1).movePawn(0);
    final plan = MatchMovePresentationPlan.fromEvents(
      events: moved.events,
      player: PlayerColor.green,
      pawnIndex: 0,
      isTeamUp: true,
    );
    expect(plan.captureCount, 0);
    expect(plan.friendlyLossCount, 1);
    expect(plan.feedback, 'STACK LOST');
    expect(plan.extraTurnGranted, isFalse);
  });
  testWidgets('own fourth finish transfers bonus without showing match victory',
      (tester) async {
    await frame(
      tester,
      MatchScreen(
        initialGame: team(
          progress: {
            PlayerColor.orange: [56, 56, 56, 55],
          },
        ),
        rollDice: () => 1,
      ),
    );
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pumpAndSettle();
    expect(find.text('ORANGE → MAGENTA'), findsOneWidget);
    expect(find.text('TEAM A · 4/8'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsNothing);
    expect((await const SavedMatchStore().load())!.game.winner, isNull);
  });
  testWidgets('winning team retains final finishing name and rematch',
      (tester) async {
    final won = team(
      active: PlayerColor.magenta,
      progress: {
        PlayerColor.orange: [56, 56, 56, 56],
        PlayerColor.magenta: [56, 56, 56, 55],
      },
    ).roll(1).movePawn(3);
    await frame(
      tester,
      MatchScreen(
        initialGame: won,
        profiles: MatchPlayerProfile.local(
          names: {PlayerColor.magenta: 'Maya'},
        ),
      ),
    );
    expect(find.text('TEAM A WINS · Maya'), findsOneWidget);
    expect(find.text('TEAM A · 8/8'), findsOneWidget);
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pumpAndSettle();
    final saved = (await const SavedMatchStore().load())!;
    expect(saved.game.configuration.mode, MatchMode.teamUp);
    expect(saved.game.winningTeam, isNull);
    expect(find.text('TEAM A · 0/8'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
  });
  testWidgets('pending transferred AI roll resumes one move without rerolling',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      () => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    final pending = team(
      progress: {
        PlayerColor.orange: [56, 56, 56, 56],
      },
    ).roll(6, commandId: 'accepted-roll');
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: pending,
          aiPlayers: const {PlayerColor.magenta},
          rollDice: () => throw StateError('No human reroll'),
        ),
      ),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect((await const SavedMatchStore().load())!.game.stateVersion, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump(const Duration(milliseconds: 200));
    final moved = (await const SavedMatchStore().load())!.game;
    expect(moved.stateVersion, 2);
    expect(moved.scheduledPlayer, PlayerColor.orange);
    expect(moved.activePlayer, PlayerColor.magenta);
    expect(moved.diceValue, isNull);
    expect(
      moved.players
          .singleWhere((p) => p.color == PlayerColor.magenta)
          .pawnProgress
          .where((v) => v == 0),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
