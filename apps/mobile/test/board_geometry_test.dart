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

    test('anchors yard pawns to the four artwork socket centers', () {
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, -1, 0),
        const NormalizedBoardPoint(1.76 / 15, 2.01 / 15),
      );
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, -1, 1),
        const NormalizedBoardPoint(3.73 / 15, 2.01 / 15),
      );
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, -1, 2),
        const NormalizedBoardPoint(1.76 / 15, 4.01 / 15),
      );
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, -1, 3),
        const NormalizedBoardPoint(3.73 / 15, 4.01 / 15),
      );
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
