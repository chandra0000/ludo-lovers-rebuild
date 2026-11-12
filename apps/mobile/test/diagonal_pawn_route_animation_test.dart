import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('diagonal visual steps retain canonical endpoints and midpoint', () {
    for (final color in PlayerColor.turnOrder) {
      for (var progress = -1; progress < 56; progress++) {
        final start = BoardGeometry.normalizedPosition(color, progress, 0);
        final end = BoardGeometry.normalizedPosition(color, progress + 1, 0);
        expect(
          BoardGeometry.interpolateRouteStep(color, progress, 0, 0),
          start,
        );
        expect(
          BoardGeometry.interpolateRouteStep(color, progress, 0, 1),
          end,
        );
        final middle = BoardGeometry.interpolateRouteStep(
          color,
          progress,
          0,
          0.5,
        );
        expect(middle.x, closeTo((start.x + end.x) / 2, 0.0000001));
        expect(middle.y, closeTo((start.y + end.y) / 2, 0.0000001));
      }
    }
  });

  test('visual interpolation clamps overshoot to legal anchors', () {
    final start = BoardGeometry.normalizedPosition(PlayerColor.orange, 0, 0);
    final end = BoardGeometry.normalizedPosition(PlayerColor.orange, 1, 0);
    expect(
      BoardGeometry.interpolateRouteStep(PlayerColor.orange, 0, 0, -1),
      start,
    );
    expect(
      BoardGeometry.interpolateRouteStep(PlayerColor.orange, 0, 0, 2),
      end,
    );
  });
}
