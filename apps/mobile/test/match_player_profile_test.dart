import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  test('local match creates one stable profile per seat', () {
    final profiles = MatchPlayerProfile.local(
      aiPlayers: {PlayerColor.green, PlayerColor.blue},
    );
    expect(profiles.map((profile) => profile.color).toList(),
        PlayerColor.turnOrder);
    expect(profiles.map((profile) => profile.playerId).toSet(), hasLength(4));
    expect(profiles.where((profile) => profile.isBot), hasLength(2));
    expect(profiles.every((profile) => profile.isConnected), isTrue);
  });

  test('profile updates do not change seat identity', () {
    final original = MatchPlayerProfile.local().first;
    final updated = original.copyWith(
      displayName: 'Player One',
      isConnected: false,
    );
    expect(updated.playerId, original.playerId);
    expect(updated.color, original.color);
    expect(updated.displayName, 'Player One');
    expect(updated.isConnected, isFalse);
    expect(original.isConnected, isTrue);
  });
}
