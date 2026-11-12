import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/game/systems/pawn_layout_solver.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('all safe-cell anchors produce stable cluster identities', () {
    final keys = <int>{};
    for (final index in BoardGeometry.safeTrackCells) {
      final point = BoardGeometry.trackPosition(index);
      expect(keys.add(PawnLayoutSolver.clusterKey(point)), isTrue);
      expect(PawnLayoutSolver.clusterKey(point),
          PawnLayoutSolver.clusterKey(point));
    }
    expect(keys, hasLength(BoardGeometry.safeTrackCells.length));
  });

  test('home lanes map to distinct cluster keys for each player', () {
    final keys = <int>{};
    for (final color in PlayerColor.turnOrder) {
      for (var step = 0; step < BoardGeometry.homeLaneLength; step++) {
        final point = BoardGeometry.homeLanePosition(color, step);
        expect(keys.add(PawnLayoutSolver.clusterKey(point)), isTrue);
      }
    }
    expect(keys, hasLength(4 * BoardGeometry.homeLaneLength));
  });

  test('one pawn is centered; two three and four use distinct stable slots',
      () {
    final center = PawnLayoutSolver.stackOffset(0, 1);
    expect(center.x, 0);
    expect(center.y, 0);
    for (final count in <int>[2, 3, 4]) {
      final offsets = [
        for (var index = 0; index < count; index++)
          PawnLayoutSolver.stackOffset(index, count),
      ];
      expect(offsets.toSet(), hasLength(count));
      expect(offsets.every((offset) => offset.x.abs() <= 9), isTrue);
      expect(offsets.every((offset) => offset.y.abs() <= 9), isTrue);
    }
  });

  test('invalid stack slots are rejected', () {
    expect(() => PawnLayoutSolver.stackOffset(0, 0), throwsRangeError);
    expect(() => PawnLayoutSolver.stackOffset(-1, 2), throwsRangeError);
    expect(() => PawnLayoutSolver.stackOffset(2, 2), throwsRangeError);
  });
}
