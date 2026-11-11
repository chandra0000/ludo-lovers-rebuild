import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
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
