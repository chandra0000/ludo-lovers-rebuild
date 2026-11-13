import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/approved_artwork_overlays.dart';
import 'package:ludo_lovers/src/features/match/approved_reference_plate.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('the reference plate renders the complete asset without a crop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 576,
            height: 1024,
            child: ApprovedReferencePlate(canvasScale: 1),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('approved_artwork_plate')), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const Key('approved_full_artwork')),
    );
    expect(image.fit, BoxFit.fill);
    expect(image.excludeFromSemantics, isTrue);
  });

  testWidgets('reference actions retain real accessible tap targets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(576, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var chat = 0;
    var more = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 576,
            height: 1024,
            child: ApprovedArtworkActionsLayer(
              onChat: () => chat++,
              onMore: () => more++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chat_button')));
    await tester.tap(find.byKey(const Key('more_button')));
    expect(chat, 1);
    expect(more, 1);
  });

  testWidgets('reference overlays show live player and turn data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(576, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ApprovedArtworkProfilesLayer(
                profiles: MatchPlayerProfile.local(
                  aiPlayers: const {PlayerColor.green},
                ),
                activeColor: PlayerColor.green,
              ),
              const ApprovedArtworkTurnOverlay(
                statusText: 'GREEN · AI TURN',
                activePlayer: PlayerColor.green,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('profile_name_green')), findsOneWidget);
    expect(find.text('GREEN · AI TURN'), findsOneWidget);
    expect(find.text('BOT'), findsWidgets);
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
  });
}
