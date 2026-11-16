import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_profiles_layer.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets(
      'HUD seat quadrants and portrait rings match the authoritative seat',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(576, 1024);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchProfilesLayer(
          profiles: MatchPlayerProfile.local(),
          activeColor: PlayerColor.orange,
        ),
      ),
    );
    for (final color in PlayerColor.turnOrder) {
      final rect = tester.getRect(find.byKey(Key('profile_${color.name}')));
      final yard = BoardGeometry.normalizedPosition(color, -1, 0);
      expect(
        rect.center.dx < 288,
        yard.x < .5,
        reason: '${color.name} HUD must sit beside its own yard',
      );
      expect(rect.center.dy < 512, yard.y < .5);
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(Key('profile_avatar_${color.name}')),
          matching: find.byType(Image),
        ),
      );
      final asset = (image.image as ResizeImage).imageProvider as AssetImage;
      final expected = switch (color) {
        PlayerColor.orange => 'avatar_aldo.webp',
        PlayerColor.green => 'avatar_you.webp',
        PlayerColor.magenta => 'avatar_emma.webp',
        PlayerColor.blue => 'avatar_bob.webp',
      };
      expect(asset.assetName, endsWith(expected));
    }
  });
  testWidgets(
      'portrait identity and accent survive every turn and reordered profiles',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(576, 1024);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final profiles = MatchPlayerProfile.local(
      names: {
        PlayerColor.orange: 'Alex',
        PlayerColor.green: 'Alex',
      },
    );
    const colors = {
      PlayerColor.orange: Color(0xFFFF8928),
      PlayerColor.green: Color(0xFF33FF28),
      PlayerColor.magenta: Color(0xFFF428FF),
      PlayerColor.blue: Color(0xFF289EFF),
    };
    for (final active in PlayerColor.turnOrder) {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchProfilesLayer(
            profiles: profiles.reversed.toList(),
            activeColor: active,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      for (final profile in profiles) {
        final badge = tester.widget<MatchPlayerBadge>(
          find.byKey(Key('profile_${profile.color.name}')),
        );
        expect(badge.profile.playerId, profile.playerId);
        expect(badge.profile.color, profile.color);
        final avatar = tester.widget<Container>(
          find.byKey(Key('profile_avatar_${profile.color.name}')),
        );
        final border = (avatar.decoration! as BoxDecoration).border! as Border;
        expect(border.top.color, colors[profile.color]);
        expect(
          find.byKey(Key('profile_seat_${profile.color.name}')),
          findsOneWidget,
        );
      }
    }
    expect(find.text('Alex'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
