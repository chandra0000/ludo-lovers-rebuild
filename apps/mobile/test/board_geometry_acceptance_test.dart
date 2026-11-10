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
          expect(
            lanes.add(cell),
            isTrue,
            reason: 'Overlapping lane cell: $cell',
          );
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
    test('canvas and source artwork share the exact 9:16 aspect ratio', () {
      expect(BoardGeometry.sourceWidth, 810);
      expect(BoardGeometry.sourceHeight, 1440);
      expect(
        BoardGeometry.canvasWidth / BoardGeometry.canvasHeight,
        closeTo(9 / 16, 1e-12),
      );
      expect(
        BoardGeometry.sourceWidth / BoardGeometry.sourceHeight,
        closeTo(9 / 16, 1e-12),
      );
    });

    test('finish anchor matches the measured centre of the artwork hub', () {
      final point = BoardGeometry.finishPosition;
      expect(point.x * BoardGeometry.sourceWidth, closeTo(403, 1e-9));
      expect(point.y * BoardGeometry.sourceHeight, closeTo(681, 1e-9));

      final canvas = BoardGeometry.canvasPosition(point);
      expect(canvas.x, closeTo(403 * 576 / 810, 1e-9));
      expect(canvas.y, closeTo(681 * 1024 / 1440, 1e-9));
    });

    test('all 52 route and 20 home-lane anchors stay inside source artwork', () {
      for (var index = 0; index < BoardGeometry.trackLength; index++) {
        final point = BoardGeometry.trackPosition(index);
        expect(point.x, inInclusiveRange(0, 1));
        expect(point.y, inInclusiveRange(0, 1));
      }
      for (final color in PlayerColor.turnOrder) {
        for (var lane = 0; lane < BoardGeometry.homeLaneLength; lane++) {
          final point = BoardGeometry.homeLanePosition(color, lane);
          expect(point.x, inInclusiveRange(0, 1));
          expect(point.y, inInclusiveRange(0, 1));
        }
      }
    });

    test('yard sockets remain in their artwork quadrants', () {
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.yardPosition(color, pawn);
          final sourceX = point.x * BoardGeometry.sourceWidth;
          final sourceY = point.y * BoardGeometry.sourceHeight;
          expect(sourceX, inInclusiveRange(0, 810));
          expect(sourceY, inInclusiveRange(0, 1440));
          if (color == PlayerColor.orange || color == PlayerColor.blue) {
            expect(sourceX, lessThan(405));
          } else {
            expect(sourceX, greaterThan(405));
          }
          if (color == PlayerColor.orange || color == PlayerColor.green) {
            expect(sourceY, lessThan(720));
          } else {
            expect(sourceY, greaterThan(720));
          }
        }
      }
    });
  });
}
