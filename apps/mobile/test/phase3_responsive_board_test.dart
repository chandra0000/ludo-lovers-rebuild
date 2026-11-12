import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';
import 'package:ludo_lovers/src/features/match/match_dice_layer.dart';
import 'package:ludo_lovers/src/features/match/match_profiles_layer.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('Phase 3: pawn anchors remain calibrated across phone sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final viewport in <Size>[
      const Size(360, 780),
      const Size(393, 873),
      const Size(412, 915),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
      await tester.pump();

      // The approved board, all player badges, dice, and chat entry point
      // must coexist with the pawn layer on every supported phone viewport.
      expect(find.byType(MatchBoardArtwork), findsOneWidget);
      expect(find.byKey(const Key('board_artwork')), findsOneWidget);
      expect(find.byType(MatchProfilesLayer), findsOneWidget);
      expect(find.byType(MatchDiceLayer), findsOneWidget);
      expect(find.byKey(const Key('animated_dice')), findsOneWidget);
      expect(find.byKey(const Key('chat_button')), findsOneWidget);
      for (final color in PlayerColor.turnOrder) {
        expect(find.byKey(Key('profile_${color.name}')), findsOneWidget);
      }

      final canvas = tester.getRect(find.byKey(const Key('match_canvas')));
      expect(canvas.width, lessThanOrEqualTo(viewport.width));
      expect(canvas.height, lessThanOrEqualTo(viewport.height));
      expect(
        canvas.width / canvas.height,
        closeTo(
          BoardGeometry.canvasWidth / BoardGeometry.canvasHeight,
          0.001,
        ),
      );

      final scale = canvas.width / BoardGeometry.canvasWidth;
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          final anchor = BoardGeometry.canvasPosition(
            BoardGeometry.normalizedPosition(color, -1, pawn),
          );
          final expected = Offset(
            canvas.left + anchor.x * scale,
            canvas.top + anchor.y * scale,
          );
          final actual = tester.getCenter(
            find.byKey(Key('pawn_${color.name}_$pawn')),
          );
          expect(
            actual.dx,
            closeTo(expected.dx, 0.5),
            reason: '${color.name} pawn $pawn horizontal at $viewport',
          );
          expect(
            actual.dy,
            closeTo(expected.dy, 0.5),
            reason: '${color.name} pawn $pawn vertical at $viewport',
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
