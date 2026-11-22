import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_profiles_layer.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('HUD seat quadrants match the approved board artwork',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 576,
            height: 1024,
            child: MatchProfilesLayer(
              profiles: MatchPlayerProfile.local(),
              activeColor: PlayerColor.orange,
            ),
          ),
        ),
      ),
    );

    final expected = <PlayerColor, Offset>{
      PlayerColor.orange: const Offset(12, 88),
      PlayerColor.green: const Offset(378, 88),
      PlayerColor.blue: const Offset(12, 832),
      PlayerColor.magenta: const Offset(378, 832),
    };
    for (final entry in expected.entries) {
      final badge = find.byKey(Key('profile_${entry.key.name}'));
      expect(badge, findsOneWidget);
      final positioned = tester.widget<Positioned>(
        find.ancestor(of: badge, matching: find.byType(Positioned)).first,
      );
      expect(positioned.left, entry.value.dx);
      expect(positioned.top, entry.value.dy);
    }
  });
}
