import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/presentation/destination_preview_painter.dart';

void main() {
  test('real route anchors follow turns and safe squares', () {
    final route = <Offset>[];
    for (var progress = 0; progress <= 8; progress++) {
      final point = BoardGeometry.canvasPosition(
        BoardGeometry.normalizedPosition(PlayerColor.orange, progress, 0),
      );
      route.add(Offset(point.x, point.y));
    }
    expect(route.length, 9);
    expect(route.first, isNot(route.last));
    expect(BoardGeometry.safeTrackCells.contains(8), isTrue);
  });

  testWidgets('animated preview route renders without changing hit targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(576, 1024),
            painter: const DestinationPreviewPainter(
              targetCenter: Offset(280, 450),
              routePoints: [
                Offset(100, 350),
                Offset(135, 350),
                Offset(135, 385),
                Offset(135, 420),
              ],
              cellSize: 36,
              playerColor: Colors.orange,
              previewType: DestinationPreviewType.standard,
              animationProgress: .5,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
