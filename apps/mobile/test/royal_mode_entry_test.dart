import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/setup/mode_selection_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final entry in [
    (id: 'ffa', mode: MatchMode.compatibility, seats: 4, bots: 0),
    (id: 'duel', mode: MatchMode.classic, seats: 2, bots: 0),
    (id: 'computer', mode: MatchMode.compatibility, seats: 4, bots: 3),
    (id: 'team', mode: MatchMode.teamUp, seats: 4, bots: 0),
  ]) {
    testWidgets(
        '${entry.id} preset opens configured setup and authoritative live match',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ModeSelectionScreen(allowInternalModes: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('launch_${entry.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(GameSetupScreen), findsOneWidget);
      final start = find
          .byKey(Key(entry.bots == 0 ? 'start_local_match' : 'start_ai_match'));
      await tester.scrollUntilVisible(
        start,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      final saved = (await const SavedMatchStore().load())!;
      expect(saved.game.configuration.mode, entry.mode);
      expect(saved.game.configuration.activePlayers, hasLength(entry.seats));
      expect(saved.aiPlayers, hasLength(entry.bots));
      expect(find.byKey(const Key('board_stage')), findsOneWidget);
      expect(find.byKey(const Key('roll_dice')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
  testWidgets('public presets do not bypass preview release gates',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ModeSelectionScreen()));
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('launch_duel')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('launch_team')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('launch_ffa')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('launch_computer')))
          .onPressed,
      isNotNull,
    );
  });
}
