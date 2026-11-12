import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('Legacy rules compatibility', () {
    test('current saves retain current rules after round-trip', () {
      final game = LudoGame.initial();
      final restored = LudoGame.fromSnapshot(game.toSnapshot());
      expect(restored.ruleProfile, LudoRuleProfile.currentV1);
      expect(restored.ruleProfile.extraTurnOnFinish, isFalse);
      expect(restored.ruleProfile.threeConsecutiveSixesPenalty, isFalse);
    });

    test('classic saves retain the explicitly selected variant', () {
      final game = LudoGame.initial(
        ruleProfile: LudoRuleProfile.classicV1,
      );
      final restored = LudoGame.fromSnapshot(game.toSnapshot());
      expect(restored.ruleProfile, LudoRuleProfile.classicV1);
      expect(restored.ruleProfile.extraTurnOnFinish, isTrue);
      expect(restored.ruleProfile.threeConsecutiveSixesPenalty, isTrue);
      expect(restored.ruleProfile.captureOnlySingleOpponentPawn, isTrue);
      expect(restored.ruleProfile.enableHardBlockade, isTrue);
    });

    test('all four seats have unique 52-cell track rotations', () {
      for (final color in PlayerColor.turnOrder) {
        final cells = <int>{
          for (var progress = 0;
              progress < BoardGeometry.trackLength;
              progress++)
            (BoardGeometry.seats[color]!.entryIndex + progress) %
                BoardGeometry.trackLength,
        };
        expect(cells.length, BoardGeometry.trackLength);
        expect(
          BoardGeometry.physicalTrackCell(color, 0),
          BoardGeometry.seats[color]!.entryIndex,
        );
      }
    });

    test('approved artwork has exactly four documented diagonal connectors',
        () {
      expect(BoardGeometry.nonOrthogonalTransitions, <int>[4, 17, 30, 43]);
      expect(
        BoardGeometry.safeTrackCells,
        <int>{0, 8, 13, 21, 26, 34, 39, 47},
      );
    });
  });
}
