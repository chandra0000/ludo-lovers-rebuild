import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';
import 'package:ludo_lovers/src/features/match/match_dice_layer.dart';
import 'package:ludo_lovers/src/features/match/match_hud_region_clipper.dart';
import 'package:ludo_lovers/src/features/match/match_profiles_layer.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('profiles and rolling dice never paint inside protected artwork',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(576, 1024);
    Widget scene(int rollId) => MaterialApp(
          home: RepaintBoundary(
            key: const Key('hud_capture'),
            child: SizedBox(
              width: 576,
              height: 1024,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: MatchProfilesLayer(
                      profiles: MatchPlayerProfile.local(),
                      activeColor: PlayerColor.orange,
                    ),
                  ),
                  Positioned.fill(
                    child: ClipPath(
                      clipper: const MatchHudRegionClipper(),
                      child: Stack(
                        children: [
                          MatchDiceLayer(
                            targetValue: 6,
                            rollId: rollId,
                            canRoll: false,
                            isWaitingForRoll: false,
                            onRollRequested: () {},
                            onAnimationComplete: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    await tester.pumpWidget(scene(0));
    await tester.pumpWidget(scene(1));
    for (final delay in [100, 200, 200]) {
      await tester.pump(Duration(milliseconds: delay));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('hud_capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final data =
              await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          expect(data, isNotNull);
          final bytes =
              data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          const rect = MatchBoardArtwork.artworkRect;
          for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
            for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
              if (bytes[(y * image.width + x) * 4 + 3] != 0) {
                fail('HUD painted protected board pixel ($x,$y)');
              }
            }
          }
        } finally {
          image.dispose();
        }
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
