import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_profiles_layer.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('match badges reflect supplied identities and connection state',
      (tester) async {
    final profiles = [
      const MatchPlayerProfile(
        playerId: 'account-1',
        displayName: 'Alex',
        color: PlayerColor.orange,
      ),
      const MatchPlayerProfile(
        playerId: 'account-2',
        displayName: 'Sam',
        color: PlayerColor.green,
        isConnected: false,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 576,
            height: 1024,
            child: MatchProfilesLayer(
              profiles: profiles,
              activeColor: PlayerColor.orange,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.byKey(const Key('profile_orange')), findsOneWidget);
  });
}
