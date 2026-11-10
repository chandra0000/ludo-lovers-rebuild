import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavedMatchStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists match state, AI seats and seed across reload', () async {
      const store = SavedMatchStore();
      final game = LudoGame.initial()
          .roll(6, commandId: 'save-roll')
          .movePawn(2, commandId: 'save-move')
          .roll(4, commandId: 'save-next-roll');
      final match = SavedMatch(
        game: game,
        aiPlayers: const {PlayerColor.green, PlayerColor.blue},
        aiSeed: 20261110,
      );

      await store.save(match);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.game.stateVersion, game.stateVersion);
      expect(restored.game.activePlayer, game.activePlayer);
      expect(restored.game.diceValue, 4);
      expect(restored.game.currentPlayer.pawnProgress[2], 0);
      expect(restored.game.appliedCommandIds, game.appliedCommandIds);
      expect(restored.aiPlayers, {PlayerColor.green, PlayerColor.blue});
      expect(restored.aiSeed, 20261110);
    });

    test('clears a saved match when explicitly requested', () async {
      const store = SavedMatchStore();
      await store.save(
        SavedMatch(
          game: LudoGame.initial(),
          aiPlayers: const {},
          aiSeed: 1,
        ),
      );

      await store.clear();

      expect(await store.load(), isNull);
    });

    test('discards corrupt saved data instead of restoring guessed state',
        () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('saved_local_match_v1', '{not-json');

      const store = SavedMatchStore();
      expect(await store.load(), isNull);
      expect(preferences.containsKey('saved_local_match_v1'), isFalse);
    });
  });
}
