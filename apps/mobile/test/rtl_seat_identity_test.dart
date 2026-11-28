import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'support/capture_artifact.dart';
import 'support/load_sdk_fonts.dart';

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final direction in TextDirection.values) {
    for (final count in [2, 3, 4]) {
      for (final size in const [
        Size(320, 640),
        Size(360, 800),
        Size(393, 873),
        Size(430, 932),
      ]) {
        testWidgets(
            '${direction.name} preserves $count physical seats at $size',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            Builder(
              builder: (context) {
                final theme =
                    (const LudoLoversApp().build(context) as MaterialApp).theme;
                return MaterialApp(
                  theme: theme,
                  builder: (_, child) =>
                      Directionality(textDirection: direction, child: child!),
                  home: MatchScreen(
                    initialGame: ModeRegistry.create(
                      MatchMode.compatibility,
                      playerCount: count,
                    ),
                  ),
                );
              },
            ),
          );
          await tester.pumpAndSettle();
          await captureArtifact(
            tester,
            '${direction.name}-seats-$count-${size.width.toInt()}x${size.height.toInt()}',
            key: const Key('match_screen_capture'),
          );
          final orange =
              tester.getCenter(find.byKey(const Key('profile_orange')));
          final green =
              tester.getCenter(find.byKey(const Key('profile_green')));
          final blue = tester.getCenter(find.byKey(const Key('profile_blue')));
          final magenta =
              tester.getCenter(find.byKey(const Key('profile_magenta')));
          expect(
            orange.dx,
            lessThan(green.dx),
            reason: 'Orange stays top-left',
          );
          expect(
            blue.dx,
            lessThan(magenta.dx),
            reason: 'Blue stays bottom-left',
          );
          expect(orange.dy, lessThan(blue.dy));
          expect(green.dy, lessThan(magenta.dy));
          final board = tester.getSize(find.byKey(const Key('board_stage')));
          expect(board.width, closeTo(board.height, .01));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
  }
}
