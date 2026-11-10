import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'fixtures/board_acceptance_presets.dart';

void main() {
  group('Board visual acceptance presets', () {
    test('fills all sixteen canonical yard sockets', () {
      final game = BoardAcceptancePresets.allYardSocketsFilled;
      for (final color in PlayerColor.turnOrder) {
        expect(game.players
            .firstWhere((player) => player.color == color)
            .pawnProgress, everyElement(-1));
        for (var pawn = 0; pawn < 4; pawn++) {
          expect(BoardGeometry.yardPosition(color, pawn), isNotNull);
        }
      }
    });

    test('provides a single pawn baseline on the shared track', () {
      final game = BoardAcceptancePresets.singlePawnOnTrack;
      expect(game.players
          .firstWhere((player => player.color == PlayerColor.orange))
          .pawnProgress.first, 5);
      expect(BoardGeometry.physicalTrackCell(PlayerColor.orange, 5), 5);
    });

    test('places two friendly pawns on physical cell 10', () {
      final game = BoardAcceptancePresets.friendlyTwoPawnStackAtCell10;
      final progress = game.players
          .firstWhere((player) => player.color == PlayerColor.orange)
          .pawnProgress;
      expect(progress.take(2), [10, 10]);
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, progress[0], 0),
        BoardGeometry.normalizedPosition(PlayerColor.orange, progress[1], 1),
      );
    });

    test('places three distinct colours on safe physical cell 21', () {
      final game = BoardAcceptancePresets.mixedThreePawnStackAtSafeCell21;
      for (final color in [
        PlayerColor.orange,
        PlayerColor.green,
        PlayerColor.magenta,
      ]) {
        final progress = game.players
            .firstWhere((player) => player.color == color)
            .pawnProgress.first;
        expect(BoardGeometry.physicalTrackCell(color, progress), 21);
      }
      expect(BoardGeometry.safeTrackCells, contains(21));
    });

    test('covers home-lane entry and goal as separate states', () {
      final home = BoardAcceptancePresets.pawnAtHomeLaneEntry;
      final goal = BoardAcceptancePresets.pawnAtGoal;
      expect(
        home.players
            .firstWhere((player) => player.color == PlayerColor.orange)
            .pawnProgress.first,
        51,
      );
      expect(
        goal.players
            .firstWhere((player) => player.color == PlayerColor.orange)
            .pawnProgress.first,
        56,
      );
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, 51, 0),
        BoardGeometry.homeLanePosition(PlayerColor.orange, 0),
      );
      expect(
        BoardGeometry.normalizedPosition(PlayerColor.orange, 56, 0),
        BoardGeometry.finishPosition,
      );
    });
  });
}
