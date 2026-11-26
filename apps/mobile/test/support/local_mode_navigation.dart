import 'package:flutter/material.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

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
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    final initial = (await const SavedMatchStore().load())!;
    expect(initial.game.configuration.mode, fixture.$1);
    await capture?.call('native-${initial.game.configuration.id}-match');
    expect(initial.game.configuration.activePlayers, hasLength(fixture.$2));
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
    expect(
      (await const SavedMatchStore().load())!.game.configuration.mode,
      fixture.$1,
    );
    await leave(); // resume -> Home
    expect(find.byKey(const Key('open_mode_selection')), findsOneWidget);
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(tester.takeException(), isNull);
}
