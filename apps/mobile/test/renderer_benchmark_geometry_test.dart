import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';

void main() {
  test('benchmark renders exactly the existing 52 shared track anchors', () {
    expect(BoardGeometry.trackLength, 52);
    expect(BoardGeometry.sharedTrack.length, 52);
    expect(BoardGeometry.sharedTrack.toSet().length, 52);
    for (var index = 0; index < BoardGeometry.trackLength; index++) {
      final point = BoardGeometry.trackPosition(index);
      expect(point.x, inInclusiveRange(0.0, 1.0));
      expect(point.y, inInclusiveRange(0.0, 1.0));
    }
    expect(BoardGeometry.canvasWidth, 576);
    expect(BoardGeometry.canvasHeight, 1024);
  });
}
