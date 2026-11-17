import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_safe_star_layer.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';

void main() {
  testWidgets('safe anchors follow rules without repainting approved stars', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: BoardGeometry.canvasWidth,
            height: BoardGeometry.canvasHeight,
            child: MatchSafeStarLayer(),
          ),
        ),
      ),
    );

    expect(BoardGeometry.starTrackCells, <int>{8, 21, 34, 47});
    expect(
      BoardGeometry.safeTrackCells,
      containsAll(BoardGeometry.starTrackCells),
    );
    expect(
      BoardGeometry.starTrackCells.intersection(
        BoardGeometry.startTrackCells,
      ),
      isEmpty,
    );

    for (final index in BoardGeometry.safeTrackCells) {
      final finder = find.byKey(Key('safe_cell_$index'));
      expect(finder, findsOneWidget);
      final point = BoardGeometry.canvasPosition(
        BoardGeometry.trackPosition(index),
      );
      final layer = tester.getTopLeft(find.byType(MatchSafeStarLayer));
      final center = tester.getCenter(finder);
      expect(center.dx - layer.dx, closeTo(point.x, 0.5));
      expect(center.dy - layer.dy, closeTo(point.y, 0.5));
    }

    expect(BoardGeometry.safeTrackCells, <int>{0, 8, 13, 21, 26, 34, 39, 47});
    expect(
      find.descendant(
        of: find.byType(MatchSafeStarLayer),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(find.byType(IgnorePointer), findsWidgets);
    final ignore = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byType(MatchSafeStarLayer),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignore.ignoring, isTrue);
  });
}
