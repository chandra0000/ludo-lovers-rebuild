import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('benchmark renders exactly the existing 52 shared track anchors', () {
    expect(BoardGeometry.trackLength, 52);
    expect(BoardGeometry.sharedTrack.length, 52);
    expect(BoardGeometry.sharedTrack.toSet().length, 52);
    for (var index = 0; index < BoardGeometry.trackLength; index++) {
      final point = BoardGeometry.trackPosition(index);
      expect(point.x, inInclusiveRange(0.0, 1.0));
      expect(point.y, inInclusiveRange(0.0, 1.0));
    }
    expect(BoardGeometry.canvasWidth, 576);
    expect(BoardGeometry.canvasHeight, 1024);
  });

  test('benchmark must use the 20 authoritative home-lane anchors', () {
    final anchors = <NormalizedBoardPoint>[];
    for (final color in PlayerColor.turnOrder) {
      for (var index = 0; index < BoardGeometry.homeLaneLength; index++) {
        final point = BoardGeometry.homeLanePosition(color, index);
        expect(point.x, inInclusiveRange(0.0, 1.0));
        expect(point.y, inInclusiveRange(0.0, 1.0));
        anchors.add(point);
      }
    }
    expect(anchors.length, 20);
    expect(anchors.toSet().length, 20);
  });

  test('benchmark must use 16 yard sockets and the exact finish anchor', () {
    final sockets = <NormalizedBoardPoint>[];
    for (final color in PlayerColor.turnOrder) {
      for (var pawn = 0; pawn < 4; pawn++) {
        final anchor = BoardGeometry.yardPosition(color, pawn);
        expect(BoardGeometry.normalizedPosition(color, -1, pawn), anchor);
        sockets.add(anchor);
        expect(
          BoardGeometry.normalizedPosition(color, 56, pawn),
          BoardGeometry.finishPosition,
        );
      }
    }
    expect(sockets.length, 16);
    expect(sockets.toSet().length, 16);
  });

  test('benchmark must preserve entry indexes and diagonal transitions', () {
    expect(BoardGeometry.nonOrthogonalTransitions, [4, 17, 30, 43]);
    for (final color in PlayerColor.turnOrder) {
      final entry = BoardGeometry.seats[color]!.entryIndex;
      expect(BoardGeometry.normalizedPosition(color, 0, 0),
          BoardGeometry.trackPosition(entry));
      for (var progress = 0; progress < 55; progress++) {
        final start = BoardGeometry.normalizedPosition(color, progress, 0);
        final midpoint = BoardGeometry.interpolateRouteStep(
          color,
          progress,
          0,
          0.5,
        );
        final end = BoardGeometry.normalizedPosition(color, progress + 1, 0);
        expect(midpoint.x, closeTo((start.x + end.x) / 2, 1e-9));
        expect(midpoint.y, closeTo((start.y + end.y) / 2, 1e-9));
      }
    }
  });
}
