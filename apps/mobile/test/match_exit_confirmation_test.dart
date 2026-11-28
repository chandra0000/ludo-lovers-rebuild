import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'support/wait_for_board_artwork.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> launch(WidgetTester tester, MatchScreen match) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => match),
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 301));
    await waitForBoardArtwork(tester);
  }

  Future<void> openExit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('exit_match')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_exit_match')), findsOneWidget);
  }

  testWidgets('cancel keeps accepted roll; confirm saves and returns',
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
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    final before =
        (await const SavedMatchStore().load())!.game.encodeSnapshot();
    await openExit(tester);
    expect(
      find.textContaining('Progress saved on this device'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('cancel_exit_match')));
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsOneWidget);
    expect(rolls, 1);
    expect(
      (await const SavedMatchStore().load())!.game.encodeSnapshot(),
      before,
    );
    await openExit(tester);
    await tester.tap(find.byKey(const Key('confirm_leave_match')));
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsNothing);
    expect(
      (await const SavedMatchStore().load())!.game.encodeSnapshot(),
      before,
    );
  });

  testWidgets('menu and system back use the same guarded confirmation',
      (tester) async {
    await launch(tester, const MatchScreen());
    await tester.tap(find.byKey(const Key('more_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit match'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_exit_match')), findsOneWidget);
    // Back dismisses the prompt; it does not discard the match.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_exit_match')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel_exit_match')));
    await tester.pumpAndSettle();
  });

  testWidgets('repeated exit callbacks cannot open duplicate dialogs',
      (tester) async {
    await launch(tester, const MatchScreen());
    final callback = tester
        .widget<IconButton>(find.byKey(const Key('exit_match')))
        .onPressed!;
    callback();
    callback();
    callback();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_exit_match')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel_exit_match')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('failed save warns without trapping the player', (tester) async {
    await launch(
      tester,
      MatchScreen(saveMatch: (_) async => throw StateError('disk failure')),
    );
    await openExit(tester);
    expect(find.textContaining('Progress could not be saved'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_leave_match')));
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsNothing);
  });

  testWidgets('cancel resumes a pending automatic move exactly once',
      (tester) async {
    final pending = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, -1, -1, -1],
      },
    ).roll(3, commandId: 'accepted');
    await tester
        .pumpWidget(MaterialApp(home: MatchScreen(initialGame: pending)));
    tester.widget<IconButton>(find.byKey(const Key('exit_match'))).onPressed!();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect((await const SavedMatchStore().load())!.game.stateVersion, 1);
    await tester.tap(find.byKey(const Key('cancel_exit_match')));
    await tester.pumpAndSettle();
    final moved = (await const SavedMatchStore().load())!.game;
    expect(moved.stateVersion, 2);
    expect(moved.players.first.pawnProgress.first, 3);
    await tester.pump(const Duration(seconds: 2));
    expect(
      (await const SavedMatchStore().load())!.game.encodeSnapshot(),
      moved.encodeSnapshot(),
    );
  });
  testWidgets('slow storage reaches an honest exit prompt within three seconds',
      (tester) async {
    final pendingWrite = Completer<void>();
    await launch(tester, MatchScreen(saveMatch: (_) => pendingWrite.future));
    await tester.tap(find.byKey(const Key('exit_match')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3001));
    await tester.pumpAndSettle();
    expect(find.textContaining('Progress could not be saved'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_leave_match')));
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsNothing);
    pendingWrite.complete();
    await tester.pump();
  });

  testWidgets('AI is paused while confirmation is open and resumes on cancel',
      (tester) async {
    await launch(
      tester,
      MatchScreen(
        initialGame: LudoGame.fromProgress(
          activePlayer: PlayerColor.green,
          pawnProgress: const {},
        ),
        aiPlayers: const {PlayerColor.green},
      ),
    );
    await openExit(tester);
    await tester.pump(const Duration(seconds: 3));
    expect((await const SavedMatchStore().load())!.game.stateVersion, 0);
    await tester.tap(find.byKey(const Key('cancel_exit_match')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pumpAndSettle();
    expect(
      (await const SavedMatchStore().load())!.game.stateVersion,
      greaterThan(0),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
