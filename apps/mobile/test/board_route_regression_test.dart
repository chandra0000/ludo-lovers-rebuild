import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('all seats traverse 51 distinct shared cells', () {
    for (final color in PlayerColor.turnOrder) {
      final visited = <int>{};
      for (var progress = 0; progress < 51; progress++) {
        final cell = BoardGeometry.physicalTrackCell(color, progress);
        expect(visited.add(cell), isTrue);
        final point = BoardGeometry.normalizedPosition(color, progress, 0);
        expect(point, BoardGeometry.trackPosition(cell));
      }
      expect(visited, hasLength(51));
    }
  });

  test('every seat enters its own home lane and reaches finish', () {
    for (final color in PlayerColor.turnOrder) {
      for (var index = 0; index < 5; index++) {
        final point = BoardGeometry.normalizedPosition(color, 51 + index, 0);
        expect(point, BoardGeometry.homeLanePosition(color, index));
      }
      final finish = BoardGeometry.normalizedPosition(color, 56, 0);
      expect(finish, BoardGeometry.finishPosition);
    }
  });

  test('all 16 pawns stay within artwork bounds', () {
    for (final color in PlayerColor.turnOrder) {
      for (var pawn = 0; pawn < 4; pawn++) {
        for (var progress = -1; progress <= 56; progress++) {
          final point = BoardGeometry.normalizedPosition(color, progress, pawn);
          expect(point.x, inInclusiveRange(0, 1));
          expect(point.y, inInclusiveRange(0, 1));
        }
      }
    }
  });

  test('all seat entries are protected shared-track cells', () {
    for (final color in PlayerColor.turnOrder) {
      final entry = BoardGeometry.seats[color]!.entryIndex;
      expect(BoardGeometry.startTrackCells, contains(entry));
      expect(BoardGeometry.safeTrackCells, contains(entry));
    }
  });
}
