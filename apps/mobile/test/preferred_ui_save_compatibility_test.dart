import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final count in [2, 3]) {
    testWidgets('preferred home resumes main local v2 save with $count seats',
        (tester) async {
      final game = LudoGame.initial(
        configuration: MatchConfiguration.local(
          MatchMode.compatibility,
          playerCount: count,
        ),
      );
      await const SavedMatchStore().save(
        SavedMatch(game: game, aiPlayers: const {}, aiSeed: 17),
      );
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resume_saved_match')));
      await tester.pumpAndSettle();
      final match = tester.widget<MatchScreen>(find.byType(MatchScreen));
      expect(match.initialGame!.configuration.activePlayers.length, count);
      expect(match.initialGame!.configuration.version, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    test('preferred UI can restore main local v2 save with $count seats', () {
      final game = LudoGame.initial(
        configuration: MatchConfiguration.local(
          MatchMode.compatibility,
          playerCount: count,
        ),
      );
      final saved = SavedMatch(game: game, aiPlayers: const {}, aiSeed: 17);
      final restored = SavedMatch.decode(saved.encode());
      expect(restored.game.configuration.version, 2);
      expect(
        restored.game.configuration.activePlayers,
        count == 2
            ? [PlayerColor.orange, PlayerColor.magenta]
            : [PlayerColor.orange, PlayerColor.green, PlayerColor.magenta],
      );
      expect(restored.game.ruleProfile, LudoRuleProfile.currentV1);
      expect(restored.game.stateVersion, game.stateVersion);
    });
  }
  test('old four-seat and Classic saves keep version1', () {
    expect(MatchConfiguration.compatibility.version, 1);
    expect(
      MatchConfiguration.local(MatchMode.classic, playerCount: 2).version,
      1,
    );
    expect(
      () => MatchConfiguration.fromJson({
        'id': 'local-current',
        'version': 1,
        'activePlayers': ['orange', 'magenta'],
      }),
      throwsFormatException,
    );
    expect(
      () => MatchConfiguration.fromJson({
        'id': 'classic',
        'version': 2,
        'activePlayers': ['orange', 'magenta'],
      }),
      throwsFormatException,
    );
  });
}
