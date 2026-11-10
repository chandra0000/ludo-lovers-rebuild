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
          final expectedY = (seat.yardRow + (pawn < 2 ? 2.0 : 3.9)) / 15;
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
          expect(point, BoardGeometry.sharedTrack[cells[progress]].normalizedCenter);
        }
      }
    });

    test('keeps safe-cell metadata within the physical shared track', () {
      expect(BoardGeometry.safeTrackCells, {0, 8, 13, 21, 26, 34, 39, 47});
      for (final index in BoardGeometry.safeTrackCells) {
        expect(index, inInclusiveRange(0, BoardGeometry.trackLength - 1));
      }
    });

    test('maps each seat home lane to five unique cells', () {
      for (final color in PlayerColor.turnOrder) {
        final lane = BoardGeometry.seats[color]!.homeLane;
        expect(lane, hasLength(BoardGeometry.homeLaneLength));
        expect(lane.toSet(), hasLength(BoardGeometry.homeLaneLength));
        expect(lane.every((cell) => cell.isInside), isTrue);
        for (var index = 0; index < lane.length; index++) {
          expect(BoardGeometry.normalizedPosition(color, 51 + index, 0), lane[index].normalizedCenter);
        }
      }
    });

    test('maps board-relative points through one canvas contract', () {
      const point = NormalizedBoardPoint(0.5, 0.5);
      final canvas = BoardGeometry.canvasPosition(point);
      expect(canvas.x, closeTo(BoardGeometry.boardLeft + BoardGeometry.boardWidth / 2, 1e-9));
      expect(canvas.y, closeTo(BoardGeometry.boardTop + BoardGeometry.boardHeight / 2, 1e-9));
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
