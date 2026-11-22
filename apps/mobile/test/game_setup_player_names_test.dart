import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';

void main() {
  testWidgets('custom local player names reach the match profiles',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameSetupScreen()));

    await tester.enterText(
      find.byKey(const Key('player_name_orange')),
      '  Alex  ',
    );
    await tester.ensureVisible(find.byKey(const Key('start_local_match')));
    await tester.tap(find.byKey(const Key('start_local_match')));
    await tester.pump();

    final match = tester.widget<MatchScreen>(find.byType(MatchScreen));
    final profiles = match.profiles!;
    expect(profiles.first.displayName, 'Alex');
    expect(profiles.first.isBot, isFalse);
    expect(profiles.length, 4);
  });

  testWidgets('AI seats keep bot labels when custom names were entered',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameSetupScreen()));

    await tester.enterText(
      find.byKey(const Key('player_name_green')),
      'Not a bot name',
    );
    await tester.ensureVisible(find.byKey(const Key('start_ai_match')));
    await tester.tap(find.byKey(const Key('start_ai_match')));
    await tester.pump();

    final match = tester.widget<MatchScreen>(find.byType(MatchScreen));
    final profiles = match.profiles!;
    expect(profiles.first.isBot, isFalse);
    expect(profiles[1].isBot, isTrue);
    expect(profiles[1].displayName, 'GREEN Bot');
  });
}
