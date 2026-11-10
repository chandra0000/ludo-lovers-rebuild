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

    test('maps all sixteen yard pawns to measured source-artwork centres', () {
      const expected = <PlayerColor, List<Offset>>{
        PlayerColor.orange: [
          Offset(114.2, 401.4),
          Offset(215, 402.6),
          Offset(115.4, 495),
          Offset(215, 497.4),
        ],
        PlayerColor.green: [
          Offset(593, 402.6),
          Offset(692.6, 402.6),
          Offset(593, 496.2),
          Offset(692.6, 497.4),
        ],
        PlayerColor.blue: [
          Offset(117.8, 872.2),
          Offset(217.4, 873.4),
          Offset(117.8, 968.2),
          Offset(217.4, 968.2),
        ],
        PlayerColor.magenta: [
          Offset(594.2, 874.6),
          Offset(691.4, 873.4),
          Offset(593, 967),
          Offset(692.6, 967),
        ],
      };

      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.yardPosition(color, pawn);
          expect(
            point.x * BoardGeometry.sourceWidth,
            closeTo(expected[color]![pawn].dx, 1e-9),
          );
          expect(
            point.y * BoardGeometry.sourceHeight,
            closeTo(expected[color]![pawn].dy, 1e-9),
          );
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
            BoardGeometry.trackPosition(cells[progress]),
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
            BoardGeometry.homeLanePosition(color, index),
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

    test('maps source artwork anchors uniformly to the 9:16 design canvas', () {
      expect(BoardGeometry.sourceWidth, 810);
      expect(BoardGeometry.sourceHeight, 1440);
      expect(
        BoardGeometry.sourceWidth / BoardGeometry.sourceHeight,
        closeTo(BoardGeometry.canvasWidth / BoardGeometry.canvasHeight, 1e-12),
      );
      const sourceAnchor = NormalizedBoardPoint(114.2 / 810, 401.4 / 1440);
      final canvas = BoardGeometry.canvasPosition(sourceAnchor);
      expect(canvas.x, closeTo(81.2089, 0.001));
      expect(canvas.y, closeTo(285.44, 0.001));
    });

    test('maps full-artwork normalized points directly to the design canvas', () {
      const point = NormalizedBoardPoint(0.5, 0.5);
      final canvas = BoardGeometry.canvasPosition(point);
      expect(canvas.x, BoardGeometry.canvasWidth / 2);
      expect(canvas.y, BoardGeometry.canvasHeight / 2);
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
