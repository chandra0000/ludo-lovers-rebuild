import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Canonical artwork pixel anchors', () {
    // Source-artwork pixel centres in sharedTrack index order. Keep this
    // complete fixture alongside BoardGeometry so edits cannot silently move
    // an untested route cell while preserving only representative anchors.
    const trackAnchors = <Offset>[
      Offset(96.5, 625),
      Offset(144.5, 625),
      Offset(192, 625),
      Offset(240, 625),
      Offset(287.5, 625),
      Offset(341, 577),
      Offset(341, 525),
      Offset(341, 476.5),
      Offset(341, 427.5),
      Offset(341, 377.5),
      Offset(341, 326),
      Offset(404, 326),
      Offset(466.5, 326),
      Offset(466.5, 377.5),
      Offset(466.5, 427.5),
      Offset(466.5, 476.5),
      Offset(466.5, 525),
      Offset(466.5, 577),
      Offset(520.5, 625),
      Offset(568, 625),
      Offset(616, 625),
      Offset(664, 625),
      Offset(712, 625),
      Offset(760, 625),
      Offset(760, 677),
      Offset(760, 729),
      Offset(712, 729),
      Offset(664, 729),
      Offset(616, 729),
      Offset(568, 729),
      Offset(520.5, 729),
      Offset(455, 785.5),
      Offset(455, 837.5),
      Offset(455, 888),
      Offset(455, 940),
      Offset(455, 991.5),
      Offset(455, 1045),
      Offset(403, 1045),
      Offset(351, 1045),
      Offset(351, 991.5),
      Offset(351, 940),
      Offset(351, 888),
      Offset(351, 837.5),
      Offset(351, 785.5),
      Offset(287.5, 729),
      Offset(240, 729),
      Offset(192, 729),
      Offset(144.5, 729),
      Offset(96.5, 729),
      Offset(48, 729),
      Offset(48, 677),
      Offset(48, 625),
    ];

    const laneAnchors = <PlayerColor, List<Offset>>{
      PlayerColor.orange: [
        Offset(96.5, 677),
        Offset(144.5, 677),
        Offset(192, 677),
        Offset(240, 677),
        Offset(287.5, 677),
      ],
      PlayerColor.green: [
        Offset(404, 377.5),
        Offset(404, 427.5),
        Offset(404, 476.5),
        Offset(404, 525),
        Offset(404, 577),
      ],
      PlayerColor.magenta: [
        Offset(712, 677),
        Offset(664, 677),
        Offset(616, 677),
        Offset(568, 677),
        Offset(520.5, 677),
      ],
      PlayerColor.blue: [
        Offset(403, 991.5),
        Offset(403, 940),
        Offset(403, 888),
        Offset(403, 837.5),
        Offset(403, 785.5),
      ],
    };

    test('pins every shared-track cell to its source-artwork centre', () {
      expect(trackAnchors, hasLength(BoardGeometry.trackLength));
      final observed = <Offset>{};

      for (var index = 0; index < trackAnchors.length; index++) {
        final point = BoardGeometry.trackPosition(index);
        final actual = Offset(
          point.x * BoardGeometry.sourceWidth,
          point.y * BoardGeometry.sourceHeight,
        );
        expect(actual.dx, closeTo(trackAnchors[index].dx, 0.001),
            reason: 'Track anchor $index horizontal pixel drift',
        );
        expect(actual.dy, closeTo(trackAnchors[index].dy, 0.001),
            reason: 'Track anchor $index vertical pixel drift',
        );
        expect(observed.add(actual), isTrue,
            reason: 'Track anchor $index overlaps another route centre',
        );
      }
      expect(observed, hasLength(52));
    });

    test('pins every home-lane cell to its source-artwork centre', () {
      final observed = <Offset>{};
      for (final color in PlayerColor.turnOrder) {
        final expected = laneAnchors[color]!;
        expect(expected, hasLength(BoardGeometry.homeLaneLength));
        for (var index = 0; index < expected.length; index++) {
          final point = BoardGeometry.homeLanePosition(color, index);
          final actual = Offset(
            point.x * BoardGeometry.sourceWidth,
            point.y * BoardGeometry.sourceHeight,
          );
          expect(actual.dx, closeTo(expected[index].dx, 0.001),
              reason: '$color lane $index horizontal pixel drift',
          );
          expect(actual.dy, closeTo(expected[index].dy, 0.001),
              reason: '$color lane $index vertical pixel drift',
          );
          expect(observed.add(actual), isTrue,
              reason: '$color lane $index overlaps another lane centre',
          );
        }
      }
      expect(observed, hasLength(20));
    });

    test('maps all track and lane anchors through one uniform canvas scale', () {
      const scale = BoardGeometry.canvasWidth / BoardGeometry.sourceWidth;
      for (var index = 0; index < BoardGeometry.trackLength; index++) {
        final source = trackAnchors[index];
        final canvas = BoardGeometry.canvasPosition(
          BoardGeometry.trackPosition(index),
        );
        expect(canvas.x, closeTo(source.dx * scale, 0.001));
        expect(canvas.y, closeTo(source.dy * scale, 0.001));
      }
      for (final color in PlayerColor.turnOrder) {
        for (var index = 0; index < BoardGeometry.homeLaneLength; index++) {
          final source = laneAnchors[color]![index];
          final canvas = BoardGeometry.canvasPosition(
            BoardGeometry.homeLanePosition(color, index),
          );
          expect(canvas.dx, closeTo(source.dx * scale, 0.001));
          expect(canvas.dy, closeTo(source.dy * scale, 0.001));
        }
      }
    });
  });
}
