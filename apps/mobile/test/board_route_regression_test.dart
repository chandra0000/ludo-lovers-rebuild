import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Board route regression', () {
    test('every seat completes 51 shared cells before its own home lane', () {
      for (final color in PlayerColor.turnOrder) {
        final entry = BoardGeometry.seats[color]!.entryIndex;
        for (var progress = 0; progress < 51; progress++) {
          final physical = (entry + progress) % BoardGeometry.trackLength;
          expect(
            BoardGeometry.physicalTrackCell(color, progress),
            physical,
            reason: '$color progress $progress',
          );
          expect(
            BoardGeometry.normalizedPosition(color, progress, 0),
            BoardGeometry.trackPosition(physical),
          );
        }
        for (var lane = 0; lane < 5; lane++) {
          expect(
            BoardGeometry.normalizedPosition(color, 51 + lane, 0),
            BoardGeometry.homeLanePosition(color, lane),
            reason: '$color home lane $lane',
          );
        }
        expect(
          BoardGeometry.normalizedPosition(color, 56, 0),
          BoardGeometry.finishPosition,
        );
      }
    });

    test('every consecutive shared-track edge is adjacent or a documented connector', () {
      for (var index = 0; index < BoardGeometry.trackLength; index++) {
        final from = BoardGeometry.sharedTrack[index];
        final nextIndex = (index + 1) % BoardGeometry.trackLength;
        final to = BoardGeometry.sharedTrack[nextIndex];
        final dx = (from.column - to.column).abs();
        final dy = (from.row - to.row).abs();
        if (BoardGeometry.cornerConnectorIndexes.contains(index)) {
          expect(dx, 1, reason: 'Connector $index x displacement');
          expect(dy, 1, reason: 'Connector $index y displacement');
        } else {
          expect(dx + dy, 1, reason: 'Unexpected jump at edge $index');
        }
      }
    });

    test('all pawn anchors stay inside the canonical artwork', () {
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          for (var progress = -1; progress <= 56; progress++) {
            final point = BoardGeometry.normalizedPosition(
              color,
              progress,
              pawn,
            );
            expect(
              point.x,
              inInclusiveRange(0, 1),
              reason: '$color pawn $pawn progress $progress x',
            );
            expect(
              point.y,
              inInclusiveRange(0, 1),
              reason: '$color pawn $pawn progress $progress y',
            );
          }
        }
      }
    });

    test('each player starts on a protected entry square', () {
      for (final color in PlayerColor.turnOrder) {
        final entry = BoardGeometry.seats[color]!.entryIndex;
        expect(BoardGeometry.startTrackCells, contains(entry));
        expect(BoardGeometry.safeTrackCells, contains(entry));
        expect(
          BoardGeometry.normalizedPosition(color, 0, 0),
          BoardGeometry.trackPosition(entry),
        );
      }
    });
  });
}
