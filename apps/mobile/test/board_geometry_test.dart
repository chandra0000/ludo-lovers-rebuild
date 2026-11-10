import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('BoardGeometry', () {
    test('defines 52 unique in-bounds shared-track cells', () {
      expect(BoardGeometry.sharedTrack, hasLength(52));
      expect(BoardGeometry.sharedTrack.toSet(), hasLength(52));
      expect(BoardGeometry.sharedTrack.every((cell) => cell.isInside), isTrue);
      expect(BoardGeometry.isStructurallyValid, isTrue);
    });

    test('retains only the four documented corner connectors', () {
      expect(
        BoardGeometry.nonOrthogonalTransitions.toSet(),
        BoardGeometry.cornerConnectorIndexes,
      );
    });

    test('keeps seat geometry independent from the turn order', () {
      expect(PlayerColor.turnOrder, [
        PlayerColor.orange,
        PlayerColor.green,
        PlayerColor.magenta,
        PlayerColor.blue,
      ]);
      expect(BoardGeometry.seats[PlayerColor.orange]!.entryIndex, 0);
      expect(BoardGeometry.seats[PlayerColor.green]!.entryIndex, 13);
      expect(BoardGeometry.seats[PlayerColor.magenta]!.entryIndex, 26);
      expect(BoardGeometry.seats[PlayerColor.blue]!.entryIndex, 39);
    });

    test('maps the four artwork yard sockets consistently in every quadrant', () {
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.normalizedPosition(color, -1, pawn);
          final seat = BoardGeometry.seats[color]!;
          final expectedX = (seat.yardColumn + (pawn.isEven ? 1.8 : 3.8)) / 15;
          final expectedY = (seat.yardRow + (pawn < 2 ? 1.8 : 3.8)) / 15;
          expect(point.x, closeTo(expectedX, 1e-9));
          expect(point.y, closeTo(expectedY, 1e-9));
        }
      }
    });

    test('maps every player-relative track progress to 51 unique physical cells', () {
      for (final color in PlayerColor.turnOrder) {
        final cells = <int>[
          for (var progress = 0; progress < BoardGeometry.playerTrackLength; progress++)
            BoardGeometry.physicalTrackCell(color, progress),
        ];
        expect(cells, hasLength(51));
        expect(cells.toSet(), hasLength(51));
        expect(cells.first, BoardGeometry.seats[color]!.entryIndex);
        for (var progress = 0; progress < BoardGeometry.playerTrackLength; progress++) {
          final point = BoardGeometry.normalizedPosition(color, progress, 0);
          expect(
            point,
            BoardGeometry.sharedTrack[cells[progress]].normalizedCenter,
          );
        }
      }
    });

    test('keeps safe-cell metadata within the physical shared track', () {
      expect(BoardGeometry.safeTrackCells, {0, 8, 13, 21, 26, 34, 39, 47});
      for (final index in BoardGeometry.safeTrackCells) {
        expect(index, inInclusiveRange(0, BoardGeometry.trackLength - 1));
      }
    });

    test('validates every route edge and isolates the four diagonal connectors', () {
      final connectors = <int>{};
      for (var index = 0; index < BoardGeometry.trackLength; index++) {
        final from = BoardGeometry.sharedTrack[index];
        final to = BoardGeometry.sharedTrack[(index + 1) % BoardGeometry.trackLength];
        final distance = (from.column - to.column).abs() +
            (from.row - to.row).abs();
        if (distance == 2) {
          connectors.add(index);
          expect((from.column - to.column).abs(), 1);
          expect((from.row - to.row).abs(), 1);
        } else {
          expect(distance, 1, reason: 'Unexpected route gap at edge $index');
        }
      }
      expect(connectors, {4, 17, 30, 43});
      expect(connectors, BoardGeometry.cornerConnectorIndexes);
    });

    test('pins provisional safe-cell IDs to their exact physical route cells', () {
      const expected = <int, BoardCell>{
        0: BoardCell(1, 6),
        8: BoardCell(6, 2),
        13: BoardCell(8, 1),
        21: BoardCell(12, 6),
        26: BoardCell(13, 8),
        34: BoardCell(8, 12),
        39: BoardCell(6, 13),
        47: BoardCell(2, 8),
      };
      expect(BoardGeometry.safeTrackCells, expected.keys.toSet());
      for (final entry in expected.entries) {
        expect(BoardGeometry.sharedTrack[entry.key], entry.value);
      }
    });

    test('defines sixteen distinct yard sockets inside their player yards', () {
      final sockets = <NormalizedBoardPoint>{};
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.normalizedPosition(color, -1, pawn);
          expect(point.x, inInclusiveRange(0, 1));
          expect(point.y, inInclusiveRange(0, 1));
          expect(sockets.add(point), isTrue);
        }
      }
      expect(sockets, hasLength(16));
    });

    test('maps each seat home lane to five unique cells', () {
      for (final color in PlayerColor.turnOrder) {
        final lane = BoardGeometry.seats[color]!.homeLane;
        expect(lane, hasLength(BoardGeometry.homeLaneLength));
        expect(lane.toSet(), hasLength(BoardGeometry.homeLaneLength));
        expect(lane.every((cell) => cell.isInside), isTrue);
        for (var index = 0; index < lane.length; index++) {
          expect(
            BoardGeometry.normalizedPosition(color, 51 + index, 0),
            lane[index].normalizedCenter,
          );
        }
      }
    });

    test('keeps home lanes disjoint from the shared track and each other', () {
      final trackCells = BoardGeometry.sharedTrack.toSet();
      final laneCells = <BoardCell>{};

      for (final color in PlayerColor.turnOrder) {
        for (final cell in BoardGeometry.seats[color]!.homeLane) {
          expect(trackCells, isNot(contains(cell)));
          expect(cell, isNot(BoardGeometry.finishCell));
          expect(laneCells.add(cell), isTrue);
        }
      }

      expect(laneCells, hasLength(4 * BoardGeometry.homeLaneLength));
    });

    test('uses value equality for physical board cells', () {
      expect(const BoardCell(3, 7), const BoardCell(3, 7));
      final duplicateCells = <BoardCell>{};
      duplicateCells.add(const BoardCell(3, 7));
      duplicateCells.add(const BoardCell(3, 7));
      expect(duplicateCells, hasLength(1));
      expect(const BoardCell(3, 7), isNot(const BoardCell(7, 3)));
    });

    test('rejects invalid pawn indexes and progress values', () {
      expect(
        () => BoardGeometry.normalizedPosition(
          PlayerColor.orange,
          -1,
          4,
        ),
        throwsRangeError,
      );
      expect(
        () => BoardGeometry.normalizedPosition(
          PlayerColor.orange,
          57,
          0,
        ),
        throwsRangeError,
      );
      expect(
        () => BoardGeometry.physicalTrackCell(PlayerColor.orange, 51),
        throwsRangeError,
      );
    });

    test('keeps the 15x15 board grid square and cells isotropic', () {
      expect(BoardGeometry.boardHeight, BoardGeometry.boardWidth);
      expect(
        BoardGeometry.gridCellSize,
        closeTo(BoardGeometry.boardWidth / BoardGeometry.gridSize, 1e-9),
      );
      final horizontal = BoardGeometry.canvasPosition(
        const NormalizedBoardPoint(1 / 15, 0),
      );
      final vertical = BoardGeometry.canvasPosition(
        const NormalizedBoardPoint(0, 1 / 15),
      );
      expect(
        horizontal.x - BoardGeometry.boardLeft,
        closeTo(vertical.y - BoardGeometry.boardTop, 1e-9),
      );
    });

    test('maps board-relative points through one canvas contract', () {
      const point = NormalizedBoardPoint(0.5, 0.5);
      final canvas = BoardGeometry.canvasPosition(point);
      expect(
        canvas.x,
        closeTo(BoardGeometry.boardLeft + BoardGeometry.boardWidth / 2, 1e-9),
      );
      expect(
        canvas.y,
        closeTo(BoardGeometry.boardTop + BoardGeometry.boardHeight / 2, 1e-9),
      );
      expect(BoardGeometry.canvasWidth, 576);
      expect(BoardGeometry.canvasHeight, 1024);
    });

    test('maps home yards, shared track, lanes and finish to normalized points', () {
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          expect(
            BoardGeometry.normalizedPosition(color, -1, pawn),
            isA<NormalizedBoardPoint>(),
          );
        }
        expect(
          BoardGeometry.normalizedPosition(color, 0, 0),
          BoardGeometry.sharedTrack[
            BoardGeometry.seats[color]!.entryIndex
          ].normalizedCenter,
        );
        expect(
          BoardGeometry.normalizedPosition(color, 55, 0),
          BoardGeometry.seats[color]!.homeLane.last.normalizedCenter,
        );
        expect(
          BoardGeometry.normalizedPosition(color, 56, 0),
          BoardGeometry.finishCell.normalizedCenter,
        );
      }
    });
  });
}
