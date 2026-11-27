import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'support/wait_for_board_artwork.dart';

void main() {
  for (final count in [2, 3]) {
    testWidgets('resumes pre-integration $count-seat save without rerolling',
        (tester) async {
      final encoded = File(
        'test/fixtures/saves/main-5d4ca3-local-$count-pending-six.json',
      ).readAsStringSync();
      SharedPreferences.setMockInitialValues({'saved_local_match_v1': encoded});
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resume_saved_match')));
      await tester.pumpAndSettle();
      final restored = tester.widget<MatchScreen>(find.byType(MatchScreen));
      expect(restored.initialGame!.configuration.activePlayers.length, count);
      expect(restored.initialGame!.configuration.version, 2);
      expect(restored.initialGame!.stateVersion, 1);
      expect(restored.initialGame!.diceValue, 6);
      expect(restored.initialGame!.ruleProfile, LudoRuleProfile.currentV1);
      expect(find.text('Éléonore'), findsWidgets);

      // A pending accepted roll must not become a new roll on restoration.
      await tester.tap(find.byKey(const Key('roll_dice')));
      await tester.pumpAndSettle();
      expect((await const SavedMatchStore().load())!.game.stateVersion, 1);
      await waitForBoardArtwork(tester);
      await tester.tap(find.byKey(const Key('pawn_orange_0')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('pawn_orange_0')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      final moved = (await const SavedMatchStore().load())!;
      expect(moved.game.stateVersion, 2);
      expect(moved.game.appliedCommandIds, contains('upgrade-pending-six'));
      expect(moved.game.appliedCommandIds, hasLength(2));
      expect(moved.game.activePlayer, PlayerColor.orange);
      expect(moved.game.players.first.pawnProgress.first, 0);
      expect(moved.profiles.first.displayName, 'Éléonore');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
