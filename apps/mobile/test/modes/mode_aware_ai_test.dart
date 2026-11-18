import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/team_up_policy.dart';

void main() {
  const ai = SeededLudoAi();
  const orange = PlayerColor.orange,
      green = PlayerColor.green,
      magenta = PlayerColor.magenta,
      blue = PlayerColor.blue;
  LudoGame team(
    Map<PlayerColor, List<int>> progress, {
    PlayerColor active = orange,
    Map<int, TeamUpTeam> priority = const {},
  }) =>
      LudoGame.fromProgress(
        activePlayer: active,
        pawnProgress: progress,
        teamCapturePriority: priority,
        ruleProfile: LudoRuleProfile.teamUpV1,
        configuration: MatchConfiguration.local(MatchMode.teamUp),
      );

  for (final difficulty in [LudoAiDifficulty.medium, LudoAiDifficulty.hard]) {
    test('${difficulty.name} rewards engine-attributed opposing team captures',
        () {
      final g = team({
        orange: [4, 10, -1, -1],
        green: [44, -1, -1, -1],
      }).roll(1);
      expect(g.movePawn(0).events.whereType<TeamPawnCaptured>(), hasLength(1));
      expect(ai.choosePawn(g, seed: 16, difficulty: difficulty), 0);
    });
    test('${difficulty.name} avoids sacrificing protected friendly stack', () {
      final g = team(
        {
          orange: [5, -1, -1, -1],
          green: [44, 7, -1, -1],
          blue: [18, -1, -1, -1],
        },
        active: green,
        priority: {5: TeamUpTeam.a},
      ).roll(1);
      expect(
        g.movePawn(0).events.whereType<TeamPawnCaptured>().single.victim,
        blue,
      );
      expect(ai.choosePawn(g, seed: 16, difficulty: difficulty), 1);
    });
    test('${difficulty.name} does not treat teammate as a capture threat', () {
      final g = team({
        orange: [21, 10, -1, -1],
        magenta: [43, -1, -1, -1],
      }).roll(1);
      expect(ai.choosePawn(g, seed: 16, difficulty: difficulty), 0);
    });
  }

  for (final mode in MatchMode.values) {
    for (final difficulty in LudoAiDifficulty.values) {
      test(
          '${mode.name}/${difficulty.name} completes reproducibly without altering dice or source state',
          () {
        String simulate() {
          final profile = switch (mode) {
            MatchMode.compatibility => LudoRuleProfile.currentV1,
            MatchMode.classic => LudoRuleProfile.classicV1,
            MatchMode.quick => LudoRuleProfile.quickV1,
            MatchMode.teamUp => LudoRuleProfile.teamUpV1,
          };
          var g = LudoGame.initial(
            ruleProfile: profile,
            configuration: MatchConfiguration.local(mode),
          );
          final random = Random(731);
          for (var turn = 0; turn < 10000 && g.winner == null; turn++) {
            g = g.roll(random.nextInt(6) + 1);
            // A third consecutive six is already resolved by the engine.
            if (g.diceValue == null) continue;
            final snapshot = g.encodeSnapshot();
            final choice = ai.choosePawn(
              g,
              seed: 731 ^ g.stateVersion,
              difficulty: difficulty,
            );
            expect(g.encodeSnapshot(), snapshot);
            if (choice == null) {
              expect(g.legalPawnIndices(), isEmpty);
              g = g.passTurn();
            } else {
              expect(g.legalPawnIndices(), contains(choice));
              expect(
                ai.choosePawn(
                  g,
                  seed: 731 ^ g.stateVersion,
                  difficulty: difficulty,
                ),
                choice,
              );
              g = g.movePawn(choice);
            }
          }
          expect(g.winner, isNotNull);
          return g.encodeSnapshot();
        }

        expect(simulate(), simulate());
      });
    }
  }
}
