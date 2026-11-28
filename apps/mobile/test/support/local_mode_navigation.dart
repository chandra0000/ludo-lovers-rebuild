import 'package:flutter/material.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'wait_for_board_artwork.dart';

/// Shared by fast widget regression and installed Android/iOS smoke tests.
Future<void> verifyLocalModeNavigation(
  WidgetTester tester, {
  Future<void> Function(String)? capture,
}) async {
  Future<void> settled() => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
  Future<void> tap(Key key) async {
    final target = find.byKey(key);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settled();
    expect(tester.takeException(), isNull);
  }

  Future<void> leave() async {
    await tap(const Key('exit_match'));
    await tap(const Key('confirm_leave_match'));
  }

  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final app = const LudoLoversApp().build(context) as MaterialApp;
        return MaterialApp(
          theme: app.theme,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(allowInternalModes: false),
        );
      },
    ),
  );
  await settled();
  for (final fixture in [
    (MatchMode.compatibility, 2),
    (MatchMode.compatibility, 3),
    (MatchMode.classic, 2),
    (MatchMode.quick, 3),
    (MatchMode.teamUp, 4),
  ]) {
    await tap(const Key('open_mode_selection'));
    final button = find.byKey(Key('mode_${fixture.$1.name}'));
    await tester.scrollUntilVisible(
      button,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await settled();
    await tester.tap(button);
    await settled();
    if (fixture.$2 != 4) {
      await tap(const Key('mode_player_count'));
      await tester.tap(find.text('${fixture.$2} players').last);
      await settled();
    }
    final start = find.byKey(const Key('start_local_match'));
    await tester.scrollUntilVisible(
      start,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await settled();
    await tester.tap(start);
    await settled();
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    await waitForBoardArtwork(tester);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    final initial = (await const SavedMatchStore().load())!;
    expect(initial.game.configuration.mode, fixture.$1);
    await capture?.call(
      fixture.$1 == MatchMode.compatibility
          ? 'native-local-${fixture.$2}-match'
          : 'native-${initial.game.configuration.id}-match',
    );
    expect(initial.game.configuration.activePlayers, hasLength(fixture.$2));
    expect(
      initial.game.configuration.version,
      fixture.$1 == MatchMode.compatibility ? 2 : 1,
    );
    await tap(const Key('roll_dice'));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tap(const Key('more_button'));
    await tester.tap(find.text('Restart match'));
    await settled();
    await tester.tap(find.text('RESTART'));
    await settled();
    expect((await const SavedMatchStore().load())!.game.stateVersion, 0);
    await leave();
    await tester.pageBack(); // setup -> mode selection
    await settled();
    await tester.pageBack(); // mode selection -> Home, refresh save
    await settled();
    expect(find.byKey(const Key('resume_saved_match')), findsOneWidget);
    await tap(const Key('resume_saved_match'));
    expect(find.byType(MatchScreen), findsOneWidget);
    await waitForBoardArtwork(tester);
    expect(
      (await const SavedMatchStore().load())!.game.configuration.mode,
      fixture.$1,
    );
    expect(
      (await const SavedMatchStore().load())!.game.configuration.activePlayers,
      hasLength(fixture.$2),
    );
    await leave(); // resume -> Home
    expect(find.byKey(const Key('open_mode_selection')), findsOneWidget);
  }
  // Re-enter a fresh setup to prove preference restoration through the live UI.
  await tap(const Key('open_mode_selection'));
  await tap(const Key('mode_compatibility'));
  final difficulty = find.byKey(const Key('ai_difficulty'));
  await tester.ensureVisible(difficulty);
  await settled();
  await tester.tap(difficulty);
  await settled();
  await tester.tap(find.text('HARD').last);
  await settled();
  await tap(const Key('start_ai_match'));
  await waitForBoardArtwork(tester);
  expect(
    tester.widget<MatchScreen>(find.byType(MatchScreen)).aiDifficulty,
    LudoAiDifficulty.hard,
  );
  expect(
    (await const SavedMatchStore().load())!.aiDifficulty,
    LudoAiDifficulty.hard,
  );
  await leave();
  await tester.pageBack();
  await settled();
  await tap(const Key('mode_compatibility'));
  expect(
    tester.widget<DropdownButton<LudoAiDifficulty>>(difficulty).value,
    LudoAiDifficulty.hard,
  );
  await capture?.call('native-preferred-ai-difficulty-setup');
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(tester.takeException(), isNull);
}
