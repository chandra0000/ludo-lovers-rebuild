import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/player_name_preferences.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  SavedMatch snapshot() => SavedMatch(
        game: LudoGame.initial().roll(6, commandId: 'saved-name-roll'),
        aiPlayers: const {PlayerColor.blue},
        aiSeed: 123,
        profiles: MatchPlayerProfile.local(
          aiPlayers: {
            PlayerColor.blue,
          },
          names: {
            PlayerColor.orange: 'Zoë 王',
            PlayerColor.green: 'Alex',
            PlayerColor.magenta: 'Alex',
          },
        ),
      );
  test(
      'schema 3 preserves names, IDs, colors and AI roles without engine changes',
      () async {
    final before = snapshot();
    await const SavedMatchStore().save(before);
    final restored = (await const SavedMatchStore().load())!;
    expect(restored.game.encodeSnapshot(), before.game.encodeSnapshot());
    expect(
      restored.profiles.map((p) => p.toJson()),
      before.profiles.map((p) => p.toJson()),
    );
    expect(restored.profiles.map((p) => p.playerId).toSet(), hasLength(4));
    expect(restored.profiles[1].displayName, restored.profiles[2].displayName);
    expect(restored.profiles[3].isBot, isTrue);
    expect(restored.profiles[3].presenceLabel, 'BOT');
    expect(() => restored.profiles.clear(), throwsUnsupportedError);
  });
  for (final version in [1, 2]) {
    test(
        'legacy saved-match schema $version preserves game and reconstructs stable seats',
        () {
      final before = snapshot();
      final json = before.toJson()
        ..['schemaVersion'] = version
        ..remove('profiles');
      if (version == 1) json.remove('aiDifficulty');
      final restored = SavedMatch.fromJson(json);
      expect(restored.game.encodeSnapshot(), before.game.encodeSnapshot());
      expect(restored.profiles.map((p) => p.color), PlayerColor.turnOrder);
      expect(
        restored.profiles.map((p) => p.playerId),
        ['local-orange', 'local-green', 'local-magenta', 'local-blue'],
      );
      expect(restored.profiles[3].isBot, isTrue);
    });
  }
  test('duplicate colors, IDs, roles and corrupt names cannot replace identity',
      () {
    for (final kind in [
      'color',
      'playerId',
      'isBot',
      'displayName',
      'missing',
    ]) {
      final json = snapshot().toJson();
      final profiles = json['profiles'] as List;
      final first = profiles[0] as Map<String, Object?>;
      if (kind == 'missing') {
        profiles.removeLast();
      } else if (kind == 'color') {
        first[kind] = 'green';
      } else if (kind == 'playerId') {
        first[kind] = 'local-green';
      } else if (kind == 'isBot') {
        first[kind] = true;
      } else {
        first[kind] = '\u202eevil';
      }
      expect(
        () => SavedMatch.fromJson(json),
        throwsFormatException,
        reason: kind,
      );
    }
  });
  test('preferred human names persist independently of saved matches',
      () async {
    const prefs = PlayerNamePreferences();
    await prefs
        .save({PlayerColor.orange: '  Zoë  王 ', PlayerColor.green: 'Alex'});
    await const SavedMatchStore().clear();
    expect(
      await prefs.load(),
      {PlayerColor.orange: 'Zoë 王', PlayerColor.green: 'Alex'},
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(PlayerNamePreferences.storageKey, '{bad json');
    expect(await prefs.load(), isEmpty);
  });
}
