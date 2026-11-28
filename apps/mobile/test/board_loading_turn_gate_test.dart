import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/load_sdk_fonts.dart';
import 'support/wait_for_board_artwork.dart';
import 'package:ludo_lovers/src/features/match/match_assets.dart';

class _SlowBoard extends ImageProvider<_SlowBoard> {
  final frame = Completer<ImageInfo>();
  @override
  Future<_SlowBoard> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(_SlowBoard key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(frame.future);

  Future<void> reveal(WidgetTester tester) async {
    final bitmap = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.orange, BlendMode.src);
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(1, 1);
      } finally {
        picture.dispose();
      }
    });
    frame.complete(ImageInfo(image: bitmap!));
    if (find.byType(MatchScreen).evaluate().isNotEmpty) {
      await waitForBoardArtwork(tester);
    }
    await tester.pump();
    await tester.pump();
    // Decode publishes the frame, readiness posts after paint, then HUD rebuilds.
    await tester.pump();
  }
}

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(393, 873),
    Size(430, 932),
  ]) {
    testWidgets('loading is readable and stable at $size with 200 percent text',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final image = _SlowBoard();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const Key('loading_capture'),
            child: MatchScreen(boardImage: image),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          MatchAssets.logo,
          tester.element(find.byType(MatchScreen)),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      final screen = Offset.zero & size;
      final labelRect = tester.getRect(find.text('Preparing your match…'));
      expect(screen.contains(labelRect.topLeft), isTrue);
      expect(screen.contains(labelRect.bottomRight), isTrue);
      expect(labelRect.height, greaterThanOrEqualTo(32));
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('prepared_match_scene')))
            .opacity,
        0,
      );
      expect(find.byKey(const Key('roll_dice')).hitTestable(), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('preparation_exit'))).shortestSide,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .widget<LuxuryDiceButton>(find.byKey(const Key('animated_dice')))
            .canRoll,
        isFalse,
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('loading_capture')),
      );
      await tester.runAsync(() async {
        final frame = await boundary.toImage();
        try {
          final data =
              (await frame.toByteData(format: ui.ImageByteFormat.png))!;
          final file = File(
            'test-artifacts/acceptance/board-loading-${size.width.toInt()}x${size.height.toInt()}-2x.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        } finally {
          frame.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox());
      await image.reveal(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('slow board blocks dice commands until the decoded frame',
      (tester) async {
    final image = _SlowBoard();
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          boardImage: image,
          rollDice: () {
            rolls++;
            return 6;
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    final dice =
        tester.widget<LuxuryDiceButton>(find.byKey(const Key('animated_dice')));
    expect(dice.canRoll, isFalse);
    dice.onRollRequested();
    expect(rolls, 0);
    expect(find.text('Preparing board'), findsOneWidget);
    await image.reveal(tester);
    expect(
      tester
          .widget<LuxuryDiceButton>(find.byKey(const Key('animated_dice')))
          .canRoll,
      isTrue,
    );
    expect(find.text('Roll dice · ORANGE'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI starts its thinking delay only after board readiness',
      (tester) async {
    final image = _SlowBoard();
    final saves = <SavedMatch>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          boardImage: image,
          aiPlayers: const {PlayerColor.orange},
          saveMatch: (snapshot) async {
            saves.add(snapshot);
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(saves.every((s) => s.game.stateVersion == 0), isTrue);
    expect(find.text('AI thinking · ORANGE'), findsNothing);
    await image.reveal(tester);
    await tester.pump(const Duration(milliseconds: 449));
    expect(saves.every((s) => s.game.stateVersion == 0), isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(saves.last.game.stateVersion, 1);
    expect(saves.last.game.events.whereType<DiceRolled>(), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'restored six cannot move before artwork; resolves once after readiness',
      (tester) async {
    final image = _SlowBoard();
    final saves = <SavedMatch>[];
    final game = LudoGame.initial().roll(6);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          boardImage: image,
          initialGame: game,
          saveMatch: (snapshot) async {
            saves.add(snapshot);
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(saves.last.game.stateVersion, game.stateVersion);
    expect(saves.last.game.currentPlayer.pawnProgress, everyElement(-1));
    await image.reveal(tester);
    await tester.pump(Duration.zero);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(saves.last.game.stateVersion, game.stateVersion + 1);
    expect(saves.last.game.currentPlayer.pawnProgress, [0, -1, -1, -1]);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('exiting during decode cannot start delayed gameplay',
      (tester) async {
    final image = _SlowBoard();
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          boardImage: image,
          aiPlayers: const {PlayerColor.orange},
          rollDice: () {
            rolls++;
            return 6;
          },
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await image.reveal(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(rolls, 0);
    expect(tester.takeException(), isNull);
  });
}
