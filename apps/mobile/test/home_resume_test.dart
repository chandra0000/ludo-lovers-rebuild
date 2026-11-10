import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home offers resume for a persisted local match', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const store = SavedMatchStore();
    final savedGame = LudoGame.initial()
        .roll(6, commandId: 'home-resume-roll')
        .movePawn(0, commandId: 'home-resume-move')
        .roll(2, commandId: 'home-resume-next-roll')
        .movePawn(0, commandId: 'home-resume-next-move');
    await store.save(
      SavedMatch(
        game: savedGame,
        aiPlayers: const {PlayerColor.blue},
        aiSeed: 42,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resume_saved_match')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resume_saved_match')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
  });
}
