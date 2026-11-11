import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/onboarding/onboarding_screen.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';
import 'package:ludo_lovers/src/app.dart';

Future<void> _capturePng(WidgetTester tester, Key key, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final logicalSize = boundary.size;
  expect(logicalSize.width, greaterThan(0));
  expect(logicalSize.height, greaterThan(0));
  expect(
    logicalSize.width / logicalSize.height,
    closeTo(BoardGeometry.canvasWidth / BoardGeometry.canvasHeight, 0.01),
  );

  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      expect(image.width, greaterThan(0));
      expect(image.height, greaterThan(0));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);

      final output = File(path);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  testWidgets(
    'home branding and primary action fit a compact phone',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('LUDO LOVERS'), findsOneWidget);
      expect(find.text('PLAY • CONNECT • LOVE'), findsOneWidget);
      expect(find.byKey(const Key('brand_logo')), findsOneWidget);
      expect(find.byKey(const Key('open_game_setup')), findsOneWidget);

      final logoSize = tester.getSize(find.byKey(const Key('brand_logo')));
      expect(logoSize.width, lessThan(160));
      expect(logoSize.height, lessThan(160));
      expect(
        tester.getSize(find.byKey(const Key('open_game_setup'))).width,
        lessThanOrEqualTo(312),
      );
    },
  );

  testWidgets('first launch shows onboarding and skip reaches home',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LudoLoversApp());
    expect(find.byKey(const Key('splash_background')), findsOneWidget);
    expect(find.text('LUDO LOVERS'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO LUDO LOVERS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('skip_onboarding')));
    await tester.pumpAndSettle();
    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.byKey(const Key('brand_logo')), findsOneWidget);
    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
  });

  testWidgets('onboarding next and get started complete first-run setup',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('WELCOME TO LUDO LOVERS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('PLAY YOUR WAY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('FOUR COLOURS. ONE BOARD.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('LUDO LOVERS'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('onboarding_completed_v1'), isTrue);
  });

  testWidgets('keeps the complete board composition responsive',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final viewport in <Size>[
      const Size(360, 800),
      const Size(393, 873),
      const Size(412, 915),
      const Size(800, 360),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
      await tester.pump();

      final canvas = tester.getSize(find.byKey(const Key('match_canvas')));
      final artwork = tester.getSize(find.byKey(const Key('board_artwork')));
      expect(canvas.width, lessThanOrEqualTo(viewport.width));
      expect(canvas.height, lessThanOrEqualTo(viewport.height));
      expect(canvas.width / canvas.height, closeTo(9 / 16, 0.001));
      expect(artwork.width / artwork.height, closeTo(835 / 851, 0.001));
      expect(
          artwork.width, closeTo(835 / 864 * BoardGeometry.canvasWidth, 0.001));
      expect(artwork.height,
          closeTo(851 / 1536 * BoardGeometry.canvasHeight, 0.001));
    }
  });

  testWidgets('places each starting pawn at its calibrated artwork socket',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump();

    final canvasRect = tester.getRect(find.byKey(const Key('match_canvas')));
    final scale = canvasRect.width / BoardGeometry.canvasWidth;

    for (final color in PlayerColor.turnOrder) {
      for (var pawnIndex = 0; pawnIndex < 4; pawnIndex++) {
        final point = BoardGeometry.normalizedPosition(color, -1, pawnIndex);
        final canvasPoint = BoardGeometry.canvasPosition(point);
        final expected = Offset(
          canvasRect.left + canvasPoint.x * scale,
          canvasRect.top + canvasPoint.y * scale,
        );
        final actual = tester.getCenter(
          find.byKey(Key('pawn_${color.name}_$pawnIndex')),
        );
        expect(actual.dx, closeTo(expected.dx, 0.5));
        expect(actual.dy, closeTo(expected.dy, 0.5));
      }
    }
  });

  testWidgets('captures the canonical match canvas at a 393x873 viewport',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump(const Duration(milliseconds: 250));

    await _capturePng(
      tester,
      const Key('match_canvas_capture'),
      'test-artifacts/match-canvas-393x873.png',
    );
  });

  testWidgets('opens a local match from the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpWidget(const LudoLoversApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_game_setup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_local_match')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_green_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_blue_0')), findsOneWidget);
  });

  testWidgets('plays a deterministic release and turn-change sequence',
      (tester) async {
    final rolls = <int>[6, 2];
    var rollIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(rollDice: () => rolls[rollIndex++]),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LuxuryDiceButton>(find.byKey(const Key('animated_dice')))
          .targetValue,
      6,
    );

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('destination_preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('luxury_dice_semantics')))
          .properties
          .button,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LuxuryDiceButton>(find.byKey(const Key('animated_dice')))
          .targetValue,
      2,
    );

    // Only the pawn already on the track can use a non-six roll, so it moves
    // automatically after the dice reveal and 350 ms anticipation window.
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 349));
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'offers a chooser when multiple legal pawns share a cell on compact phones',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);

    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [0, 0, -1, -1],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game, rollDice: () => 2),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    final firstHitTarget =
        tester.getRect(find.byKey(const Key('pawn_orange_0')));
    final secondHitTarget =
        tester.getRect(find.byKey(const Key('pawn_orange_1')));
    expect(firstHitTarget.width, greaterThanOrEqualTo(44));
    expect(firstHitTarget.height, greaterThanOrEqualTo(44));
    expect(secondHitTarget.width, greaterThanOrEqualTo(44));
    expect(secondHitTarget.height, greaterThanOrEqualTo(44));

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CHOOSE A PAWN'), findsOneWidget);
    expect(find.text('Pawn 1'), findsOneWidget);
    expect(find.text('Pawn 2'), findsOneWidget);

    await tester.tap(find.text('Pawn 2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('destination_preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pawn_orange_1')));
    await tester.pumpAndSettle();
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
  });
  testWidgets('AI dice roll animates before its move or turn pass',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MatchScreen(
          aiPlayers: {PlayerColor.orange},
          aiSeed: 17,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 460));
    await tester.pump();

    final rollingDice = tester.widget<LuxuryDiceButton>(
      find.byKey(const Key('animated_dice')),
    );
    expect(rollingDice.targetValue, isNotNull);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const Key('luxury_dice_semantics')),
          )
          .properties
          .label,
      'Dice rolling',
    );

    await tester.pump(const Duration(milliseconds: 650));
    // A no-legal-move result is held for 600 ms before the turn is passed.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Semantics>(
            find.byKey(const Key('luxury_dice_semantics')),
          )
          .properties
          .label,
      isNot('Dice rolling'),
    );
  });

  testWidgets('passes a turn after the animated roll when no pawn can move',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(rollDice: () => 4),
      ),
    );
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump();
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);

    // Complete the 600 ms dice reveal, then the 600 ms visible no-move delay.
    await tester.pump(const Duration(milliseconds: 610));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
  });

  testWidgets(
    'animates a released pawn through its route instead of teleporting',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(rollDice: () => 6),
        ),
      );
      await tester.tap(find.byKey(const Key('roll_dice')));
      await tester.pumpAndSettle();

      final pawn = find.byKey(const Key('pawn_orange_0'));
      final start = tester.getTopLeft(pawn);
      await tester.tap(pawn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('destination_preview')), findsOneWidget);
      await tester.tap(pawn);
      // The first frame establishes the ticker start time; advance it only
      // after that frame so this assertion samples actual interpolation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 55));
      final inMotion = tester.getTopLeft(pawn);
      expect(inMotion, isNot(start));

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final finish = tester.getTopLeft(pawn);
      expect(finish, isNot(inMotion));
      expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
    },
  );

  testWidgets(
    'blocks a new dice roll until pawn movement animation completes',
    (tester) async {
      var rollCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(
            rollDice: () {
              rollCount++;
              return 6;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('roll_dice')));
      await tester.pumpAndSettle();
      expect(rollCount, 1);

      final pawn = find.byKey(const Key('pawn_orange_0'));
      await tester.tap(pawn);
      await tester.pumpAndSettle();
      await tester.tap(pawn);
      await tester.pump(const Duration(milliseconds: 40));

      final dice = tester.widget<LuxuryDiceButton>(
        find.byKey(const Key('animated_dice')),
      );
      expect(dice.canRoll, isFalse);

      await tester.tap(find.byKey(const Key('roll_dice')));
      await tester.pump(const Duration(milliseconds: 40));
      expect(rollCount, 1);

      await tester.pumpAndSettle();
      final readyDice = tester.widget<LuxuryDiceButton>(
        find.byKey(const Key('animated_dice')),
      );
      expect(readyDice.canRoll, isTrue);
      await tester.tap(find.byKey(const Key('roll_dice')));
      await tester.pump();
      expect(rollCount, 2);
    },
  );

  testWidgets('completes pawn movement immediately with reduced motion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MatchScreen(rollDice: () => 6),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
    expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
  });

  testWidgets('shows capture feedback after a capturing move', (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [4, -1, -1, -1],
        PlayerColor.green: [44, -1, -1, -1],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game, rollDice: () => 1),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    // Exactly one pawn can move, so the match screen moves it automatically
    // after the 350 ms anticipation window.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('CAPTURE! EXTRA TURN'), findsOneWidget);
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);
  });

  testWidgets('shows home feedback when a pawn reaches the finish',
      (tester) async {
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        PlayerColor.orange: [55, -1, -1, -1],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(initialGame: game, rollDice: () => 1),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    // Exactly one pawn can move, so wait for the automatic move and its
    // completion feedback rather than tapping a temporarily disabled pawn.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('PAWN HOME!'), findsOneWidget);
  });

  testWidgets(
    'supports one, two, three and four human seat configurations',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 873);
      SharedPreferences.setMockInitialValues({
        'onboarding_completed_v1': true,
      });
      await tester.pumpWidget(const LudoLoversApp());
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_game_setup')));
      await tester.pumpAndSettle();

      for (final humanCount in [1, 2, 3, 4]) {
        if (humanCount != 1) {
          await tester.tap(find.byKey(const Key('human_player_count')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('$humanCount').last);
          await tester.pumpAndSettle();
        }
        final startAiMatch = find.byKey(const Key('start_ai_match'));
        await tester.ensureVisible(startAiMatch);
        await tester.pumpAndSettle();
        await tester.tap(startAiMatch);
        await tester.pumpAndSettle();

        final match = tester.widget<MatchScreen>(find.byType(MatchScreen));
        expect(
          match.aiPlayers,
          PlayerColor.turnOrder.skip(humanCount).toSet(),
        );
        expect(find.byKey(const Key('roll_dice')), findsOneWidget);
        await tester.tap(find.byKey(const Key('exit_match')));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('board preview shows all sixteen provisional yard anchors',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpWidget(const LudoLoversApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_game_setup')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open_board_preview')),
      300,
    );
    await tester.tap(find.byKey(const Key('open_board_preview')));
    await tester.pumpAndSettle();

    expect(find.text('BOARD PREVIEW'), findsOneWidget);
    expect(find.byKey(const Key('board_preview_canvas')), findsOneWidget);
    expect(find.byKey(const Key('board_preview_artwork')), findsOneWidget);
    final previewSize = tester.getSize(
      find.byKey(const Key('board_preview_canvas')),
    );
    expect(
      previewSize.width / previewSize.height,
      closeTo(BoardGeometry.canvasWidth / BoardGeometry.canvasHeight, 0.001),
    );
    for (final color in PlayerColor.turnOrder) {
      for (var pawn = 0; pawn < 4; pawn++) {
        expect(find.byKey(Key('preview_${color.name}_$pawn')), findsOneWidget);
      }
    }
    expect(find.textContaining('Diagnostic only'), findsOneWidget);
    expect(find.byKey(const Key('preview_track_0')), findsOneWidget);
    expect(find.byKey(const Key('preview_track_51')), findsOneWidget);
    expect(find.byKey(const Key('preview_finish')), findsOneWidget);
    expect(find.byKey(const Key('preview_finish_crosshair')), findsOneWidget);
    expect(find.byKey(const Key('preview_track_0_crosshair')), findsOneWidget);
    expect(
      find.byKey(const Key('preview_orange_0_crosshair')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('preview_lane_orange_0')), findsOneWidget);
    await _capturePng(
      tester,
      const Key('board_preview_capture'),
      'test-artifacts/board-preview-calibration-393x873.png',
    );
  });
}
