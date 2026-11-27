import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';
import 'support/capture_artifact.dart';
import 'support/load_sdk_fonts.dart';

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final count in [2, 3]) {
    for (final size in [
      const Size(320, 640),
      const Size(360, 800),
      const Size(393, 873),
      const Size(430, 932),
    ]) {
      testWidgets('$count local seats and smaller dice at $size',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await tester.pumpWidget(
          MaterialApp(
            home: MatchScreen(
              initialGame: ModeRegistry.create(
                MatchMode.compatibility,
                playerCount: count,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<LuxuryDiceButton>(find.byType(LuxuryDiceButton))
              .visualScale,
          .88,
        );
        final touch =
            tester.getRect(find.byKey(const Key('luxury_dice_gesture')));
        expect(touch.width, greaterThanOrEqualTo(64));
        expect(touch.height, greaterThanOrEqualTo(64));
        final board = tester.getRect(find.byKey(const Key('board_stage')));
        expect(board.width, closeTo(board.height, .01));
        final orange =
            tester.getCenter(find.byKey(const Key('profile_orange')));
        final magenta =
            tester.getCenter(find.byKey(const Key('profile_magenta')));
        expect(orange.dx, lessThan(magenta.dx));
        expect(orange.dy, lessThan(magenta.dy));
        expect(tester.takeException(), isNull);
        await captureArtifact(
          tester,
          'local-$count-${size.width.toInt()}x${size.height.toInt()}',
          key: const Key('match_screen_capture'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }

  testWidgets(
      '12 percent visual shrink preserves touch and authoritative value',
      (tester) async {
    Size? originalCube;
    for (final scale in [1.0, .88]) {
      var rolls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LuxuryDiceButton(
              key: ValueKey(scale),
              size: 64,
              visualScale: scale,
              targetValue: null,
              rollId: 0,
              canRoll: true,
              isWaitingForRoll: true,
              onRollRequested: () => rolls++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cube = tester.getSize(find.byKey(const Key('six_face_dice_cube')));
      final target =
          tester.getRect(find.byKey(const Key('luxury_dice_gesture')));
      expect(target.size, const Size(64, 64));
      if (scale == 1) {
        originalCube = cube;
      } else {
        expect(cube.width, closeTo(originalCube!.width * .88, .001));
        expect(cube.height, closeTo(originalCube.height * .88, .001));
      }
      await tester.tapAt(target.topLeft + const Offset(1, 1));
      await tester.tapAt(target.topLeft + const Offset(1, 1));
      expect(rolls, 1);
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LuxuryDiceButton(
              key: ValueKey(scale),
              size: 64,
              visualScale: scale,
              targetValue: 6,
              rollId: 1,
              canRoll: false,
              isWaitingForRoll: false,
              onRollRequested: () => rolls++,
              onAnimationComplete: () => completions++,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tapAt(target.center);
      await tester.pump(const Duration(milliseconds: 750));
      expect(rolls, 1);
      expect(completions, 1);
      expect(find.bySemanticsLabel('Dice, value 6'), findsOneWidget);
    }
  });
}
