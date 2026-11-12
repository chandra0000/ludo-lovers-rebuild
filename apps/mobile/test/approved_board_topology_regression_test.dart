import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('all 52 shared squares match approved board grid topology', () {
    const expected = <BoardCell>[
      BoardCell(1, 6),
      BoardCell(2, 6),
      BoardCell(3, 6),
      BoardCell(4, 6),
      BoardCell(5, 6),
      BoardCell(6, 5),
      BoardCell(6, 4),
      BoardCell(6, 3),
      BoardCell(6, 2),
      BoardCell(6, 1),
      BoardCell(6, 0),
      BoardCell(7, 0),
      BoardCell(8, 0),
      BoardCell(8, 1),
      BoardCell(8, 2),
      BoardCell(8, 3),
      BoardCell(8, 4),
      BoardCell(8, 5),
      BoardCell(9, 6),
      BoardCell(10, 6),
      BoardCell(11, 6),
      BoardCell(12, 6),
      BoardCell(13, 6),
      BoardCell(14, 6),
      BoardCell(14, 7),
      BoardCell(14, 8),
      BoardCell(13, 8),
      BoardCell(12, 8),
      BoardCell(11, 8),
      BoardCell(10, 8),
      BoardCell(9, 8),
      BoardCell(8, 9),
      BoardCell(8, 10),
      BoardCell(8, 11),
      BoardCell(8, 12),
      BoardCell(8, 13),
      BoardCell(8, 14),
      BoardCell(7, 14),
      BoardCell(6, 14),
      BoardCell(6, 13),
      BoardCell(6, 12),
      BoardCell(6, 11),
      BoardCell(6, 10),
      BoardCell(6, 9),
      BoardCell(5, 8),
      BoardCell(4, 8),
      BoardCell(3, 8),
      BoardCell(2, 8),
      BoardCell(1, 8),
      BoardCell(0, 8),
      BoardCell(0, 7),
      BoardCell(0, 6),
    ];
    expect(BoardGeometry.sharedTrack, expected);
    expect(BoardGeometry.nonOrthogonalTransitions, [4, 17, 30, 43]);
    expect(BoardGeometry.isStructurallyValid, isTrue);
  });

  test('entry and star cells stay anchored to approved artwork', () {
    expect(BoardGeometry.startTrackCells, {0, 13, 26, 39});
    expect(BoardGeometry.starTrackCells, {8, 21, 34, 47});
    expect(BoardGeometry.safeTrackCells, {0, 8, 13, 21, 26, 34, 39, 47});
    for (final color in PlayerColor.turnOrder) {
      final entry = BoardGeometry.seats[color]!.entryIndex;
      expect(BoardGeometry.physicalTrackCell(color, 0), entry);
      expect(BoardGeometry.physicalTrackCell(color, 50), (entry + 50) % 52);
      final lastShared = BoardGeometry.normalizedPosition(color, 50, 0);
      final firstHome = BoardGeometry.normalizedPosition(color, 51, 0);
      final lastHome = BoardGeometry.normalizedPosition(color, 55, 0);
      final finish = BoardGeometry.normalizedPosition(color, 56, 0);
      expect(lastShared, isNot(firstHome));
      expect(firstHome, BoardGeometry.homeLanePosition(color, 0));
      expect(lastHome, BoardGeometry.homeLanePosition(color, 4));
      expect(finish, BoardGeometry.finishPosition);
    }
  });

  test('artwork source anchors stay inside canonical image bounds', () {
    for (var index = 0; index < BoardGeometry.trackLength; index++) {
      final point = BoardGeometry.trackPosition(index);
      final x = point.x * BoardGeometry.sourceWidth;
      final y = point.y * BoardGeometry.sourceHeight;
      expect(x, inInclusiveRange(0, BoardGeometry.sourceWidth));
      expect(y, inInclusiveRange(0, BoardGeometry.sourceHeight));
    }
  });
}
