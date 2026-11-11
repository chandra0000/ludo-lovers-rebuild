import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  group('LudoRuleProfile behavior contract', () {
    test('extraTurnOnSix controls whether a six retains the active seat', () {
      const profile = LudoRuleProfile(
        id: 'no-six-bonus',
        version: 1,
        extraTurnOnSix: false,
      );

      final moved = LudoGame.initial(ruleProfile: profile).roll(6).movePawn(0);

      expect(moved.activePlayer, PlayerColor.green);
      expect(moved.events.whereType<ExtraTurnGranted>(), isEmpty);
    });

    test('extraTurnOnCapture controls capture bonus independently of six', () {
      const profile = LudoRuleProfile(
        id: 'no-capture-bonus',
        version: 1,
        extraTurnOnCapture: false,
      );
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: profile,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, -1, -1, -1],
        },
      );

      final moved = game.roll(2).movePawn(0);

      expect(moved.events.whereType<PawnCaptured>(), hasLength(1));
      expect(moved.activePlayer, PlayerColor.green);
      expect(moved.events.whereType<ExtraTurnGranted>(), isEmpty);
    });

    test('extraTurnOnFinish independently controls finish bonus', () {
      for (final enabled in [false, true]) {
        final profile = LudoRuleProfile(
          id: 'finish-bonus-$enabled',
          version: 1,
          extraTurnOnFinish: enabled,
        );
        final moved = LudoGame.fromProgress(
          activePlayer: PlayerColor.orange,
          ruleProfile: profile,
          pawnProgress: {
            PlayerColor.orange: [55, -1, -1, -1],
          },
        ).roll(1).movePawn(0);

        expect(
          moved.activePlayer,
          enabled ? PlayerColor.orange : PlayerColor.green,
        );
        expect(
          moved.events.whereType<ExtraTurnGranted>(),
          enabled ? hasLength(1) : isEmpty,
        );
      }
    });

    test('captureOnlySingleOpponentPawn protects a multi-pawn destination', () {
      final game = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        ruleProfile: LudoRuleProfile.classicV1,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(2);

      expect(
        game.evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.landingOnProtectedStack,
        ),
      );
      expect(game.legalPawnIndices(), isEmpty);
    });

    test('compatibility profile preserves capture-all stack behavior', () {
      final moved = LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: {
          PlayerColor.orange: [3, -1, -1, -1],
          PlayerColor.green: [44, 44, -1, -1],
        },
      ).roll(2).movePawn(0);

      expect(moved.events.whereType<PawnCaptured>(), hasLength(2));
      expect(
        moved.players
            .firstWhere((player) => player.color == PlayerColor.green)
            .pawnProgress,
        [-1, -1, -1, -1],
      );
    });

    test('enableHardBlockade controls intermediate-path legality', () {
      const softStack = LudoRuleProfile(
        id: 'soft-stack',
        version: 1,
        captureOnlySingleOpponentPawn: true,
        enableHardBlockade: false,
      );
      const hardBlockade = LudoRuleProfile(
        id: 'hard-blockade',
        version: 1,
        captureOnlySingleOpponentPawn: true,
        enableHardBlockade: true,
      );

      LudoGame build(LudoRuleProfile profile) => LudoGame.fromProgress(
            activePlayer: PlayerColor.orange,
            ruleProfile: profile,
            pawnProgress: {
              PlayerColor.orange: [3, -1, -1, -1],
              PlayerColor.green: [44, 44, -1, -1],
            },
          ).roll(4);

      expect(build(softStack).evaluatePawnMove(0), isA<ValidMove>());
      expect(
        build(hardBlockade).evaluatePawnMove(0),
        isA<InvalidMove>().having(
          (result) => result.reason,
          'reason',
          MoveInvalidReason.pathBlockedByBlockade,
        ),
      );
    });

    test('all rule-profile fields survive snapshot encode and decode', () {
      const profile = LudoRuleProfile(
        id: 'profile-round-trip',
        version: 7,
        extraTurnOnSix: false,
        extraTurnOnCapture: false,
        extraTurnOnFinish: true,
        threeConsecutiveSixesPenalty: true,
        captureOnlySingleOpponentPawn: true,
        enableHardBlockade: true,
      );

      final restored = LudoGame.decodeSnapshot(
        LudoGame.initial(ruleProfile: profile).encodeSnapshot(),
      );

      expect(restored.ruleProfile, profile);
      expect(restored.ruleProfile.id, 'profile-round-trip');
      expect(restored.ruleProfile.version, 7);
    });
  });
}
