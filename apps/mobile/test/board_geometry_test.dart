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

    test('anchors every color yard to its four artwork socket centers', () {
      const expected = <PlayerColor, List<NormalizedBoardPoint>>{
        PlayerColor.orange: <NormalizedBoardPoint>[
          NormalizedBoardPoint(1.76, 2.01),
          NormalizedBoardPoint(3.73, 2.01),
          NormalizedBoardPoint(1.76, 4.01),
          NormalizedBoardPoint(3.73, 4.01),
        ],
        PlayerColor.green: <NormalizedBoardPoint>[
          NormalizedBoardPoint(10.60, 2.01),
          NormalizedBoardPoint(12.60, 2.01),
          NormalizedBoardPoint(10.60, 4.01),
          NormalizedBoardPoint(12.60, 4.01),
        ],
        PlayerColor.magenta: <NormalizedBoardPoint>[
          NormalizedBoardPoint(10.60, 12.01),
          NormalizedBoardPoint(12.60, 12.01),
          NormalizedBoardPoint(10.60, 14.01),
          NormalizedBoardPoint(12.60, 14.01),
        ],
        PlayerColor.blue: <NormalizedBoardPoint>[
          NormalizedBoardPoint(1.76, 12.01),
          NormalizedBoardPoint(3.73, 12.01),
          NormalizedBoardPoint(1.76, 14.01),
          NormalizedBoardPoint(3.73, 14.01),
        ],
      };
      for (final color in PlayerColor.turnOrder) {
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.normalizedPosition(color, -1, pawn);
          expect(point.x, closeTo(expected[color]![pawn].x / 15, 0.000001));
          expect(point.y, closeTo(expected[color]![pawn].y / 15, 0.000001));
        }
      }
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
