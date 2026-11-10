import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Board topology acceptance', () {
    test('shared track is a unique, in-bounds 52-cell closed loop', () {
      expect(BoardGeometry.sharedTrack, hasLength(52));
      expect(BoardGeometry.sharedTrack.toSet(), hasLength(52));

      for (final cell in BoardGeometry.sharedTrack) {
        expect(cell.isInside, isTrue, reason: 'Out-of-bounds cell: $cell');
      }

      for (var index = 0; index < BoardGeometry.trackLength; index++) {
        final current = BoardGeometry.sharedTrack[index];
        final next = BoardGeometry.sharedTrack[(index + 1) % BoardGeometry.trackLength];
        final distance = (current.column - next.column).abs() +
            (current.row - next.row).abs();
        expect(
          distance,
          inInclusiveRange(1, 2),
          reason: 'Broken route between track indexes $index and '
              '${(index + 1) % BoardGeometry.trackLength}.',
        );
      }
    });

    test('only the four documented corner transitions are diagonal', () {
      expect(
        BoardGeometry.nonOrthogonalTransitions.toSet(),
        equals(BoardGeometry.cornerConnectorIndexes),
      );
      expect(BoardGeometry.cornerConnectorIndexes, {4, 17, 30, 43});
    });

    test('home lanes are disjoint from track, finish and each other', () {
      final track = BoardGeometry.sharedTrack.toSet();
      final lanes = <BoardCell>{};

      for (final color in PlayerColor.turnOrder) {
        final lane = BoardGeometry.seats[color]!.homeLane;
        expect(lane, hasLength(BoardGeometry.homeLaneLength));
        for (final cell in lane) {
          expect(cell.isInside, isTrue);
          expect(track.contains(cell), isFalse);
          expect(cell, isNot(BoardGeometry.finishCell));
          expect(lanes.add(cell), isTrue, reason: 'Overlapping lane cell: $cell');
        }
      }
      expect(lanes, hasLength(20));
    });

    test('all player entries and safe cells match the board contract', () {
      for (final color in PlayerColor.turnOrder) {
        final entry = BoardGeometry.seats[color]!.entryIndex;
        expect(entry, color.entryIndex);
        expect(BoardGeometry.safeTrackCells.contains(entry), isTrue);
        expect(BoardGeometry.physicalTrackCell(color, 0), entry);
      }
      expect(
        BoardGeometry.safeTrackCells,
        {0, 8, 13, 21, 26, 34, 39, 47},
      );
    });

    test('structural validation release gate remains explicit', () {
      expect(BoardGeometry.isStructurallyValid, isTrue);
      // Structural validity is not a substitute for visual approval.
      expect(BoardGeometry.visualApprovalPending, isTrue);
    });
  });

  group('Board canvas alignment contract', () {
    test('canvas is 9:16 and the logical board remains square', () {
      expect(
        BoardGeometry.canvasWidth / BoardGeometry.canvasHeight,
        closeTo(9 / 16, 1e-12),
      );
      expect(BoardGeometry.boardWidth, BoardGeometry.boardHeight);
    });

    test('finish point maps to the exact centre of the board grid', () {
      final point = BoardGeometry.finishCell.normalizedCenter;
      expect(point.x, closeTo(0.5, 1e-12));
      expect(point.y, closeTo(0.5, 1e-12));

      final canvas = BoardGeometry.canvasPosition(point);
      expect(
        canvas.x,
        closeTo(BoardGeometry.boardLeft + BoardGeometry.boardWidth / 2, 1e-9),
      );
      expect(
        canvas.y,
        closeTo(BoardGeometry.boardTop + BoardGeometry.boardHeight / 2, 1e-9),
      );
    });

    test('yard sockets remain inside their assigned quadrants', () {
      for (final color in PlayerColor.turnOrder) {
        final seat = BoardGeometry.seats[color]!;
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.normalizedPosition(color, -1, pawn);
          expect(
            point.x,
            inInclusiveRange(seat.yardColumn / 15, (seat.yardColumn + 6) / 15),
          );
          expect(
            point.y,
            inInclusiveRange(seat.yardRow / 15, (seat.yardRow + 6) / 15),
          );
        }
      }
    });
  });
}
