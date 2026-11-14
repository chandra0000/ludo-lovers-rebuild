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
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.byKey(const Key('profile_orange')), findsOneWidget);
    expect(find.byKey(const Key('profile_green')), findsOneWidget);
    final avatars = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(avatars, hasLength(2));
    final first = avatars[0].image;
    final second = avatars[1].image;
    expect(first, isA<ResizeImage>());
    expect(second, isA<ResizeImage>());
    final firstSource = (first as ResizeImage).imageProvider as AssetImage;
    final secondSource = (second as ResizeImage).imageProvider as AssetImage;

    expect(
      firstSource.assetName,
      'assets/images/board/extracted/avatar_aldo.webp',
    );
    expect(
      secondSource.assetName,
      'assets/images/board/extracted/avatar_you.webp',
    );
  });

  testWidgets('local player and AI badges never display ONLINE',
      (tester) async {
    final profiles = MatchPlayerProfile.local(
      aiPlayers: {PlayerColor.green},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 186,
                height: 60,
                child: MatchPlayerBadge(
                  profile: profiles.first,
                  isActive: true,
                ),
              ),
              SizedBox(
                width: 186,
                height: 60,
                child: MatchPlayerBadge(
                  profile: profiles[1],
                  isActive: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('LOCAL'), findsOneWidget);
    expect(find.text('BOT'), findsOneWidget);
    expect(find.text('ONLINE'), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
  });
}
