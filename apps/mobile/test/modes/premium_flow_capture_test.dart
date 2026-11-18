import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/setup/mode_selection_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import '../support/capture_artifact.dart';
import '../support/load_sdk_fonts.dart';

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('flow_capture'),
        child: Builder(
          builder: (context) {
            // Reuse the live application theme, rather than a capture-only design.
            final app = const LudoLoversApp().build(context) as MaterialApp;
            return MaterialApp(
              theme: app.theme,
              debugShowCheckedModeBanner: false,
              home: child,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    await captureArtifact(tester, name, key: const Key('flow_capture'));
    expect(tester.takeException(), isNull);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  for (final entry in <String, Widget>{
    'flow-home': const HomeScreen(allowInternalModes: true),
    'flow-mode-selection': const ModeSelectionScreen(allowInternalModes: true),
    'flow-classic-setup': const GameSetupScreen(
      mode: MatchMode.classic,
      allowInternalModes: true,
    ),
    'flow-quick-setup':
        const GameSetupScreen(mode: MatchMode.quick, allowInternalModes: true),
    'flow-team-up-setup':
        const GameSetupScreen(mode: MatchMode.teamUp, allowInternalModes: true),
  }.entries) {
    testWidgets('capture live ${entry.key}', (tester) async {
      await mount(tester, entry.value);
      await capture(tester, entry.key);
      if (entry.key == 'flow-classic-setup') {
        await tester.scrollUntilVisible(
          find.byKey(const Key('start_ai_match')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await capture(tester, 'flow-ai-setup');
      }
      await dispose(tester);
    });
  }
  testWidgets('capture authoritative dice, selection and capture',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, 10, -1, -1],
        PlayerColor.green: [44, -1, -1, -1],
      },
    );
    await mount(tester, MatchScreen(initialGame: game, rollDice: () => 1));
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump(const Duration(milliseconds: 80));
    await capture(tester, 'flow-dice-rolling');
    await tester.pump(const Duration(seconds: 2));
    await capture(tester, 'flow-pawn-selection');
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pump(const Duration(milliseconds: 40));
    await capture(tester, 'flow-capture');
    await tester.pump(const Duration(seconds: 2));
    await dispose(tester);
  });
  testWidgets('capture cell-by-cell movement at gameplay scale',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, 10, -1, -1],
      },
    ).roll(4);
    await mount(tester, MatchScreen(initialGame: game));
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pump(const Duration(milliseconds: 20));
    await capture(tester, 'flow-pawn-moving');
    await tester.pump(const Duration(seconds: 2));
    await dispose(tester);
  });
  testWidgets('capture winner and actual rematch', (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [55, 56, 56, 56],
      },
    ).roll(1);
    await mount(tester, MatchScreen(initialGame: game));
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    await capture(tester, 'flow-winning');
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pumpAndSettle();
    await capture(tester, 'flow-rematch');
    await dispose(tester);
  });
}
