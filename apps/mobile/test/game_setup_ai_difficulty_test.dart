import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';

void main() {
  testWidgets('player can select a seeded AI difficulty before starting', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    await tester.pumpWidget(
      const MaterialApp(home: GameSetupScreen()),
    );

    final difficultyPicker = find.byKey(const Key('ai_difficulty'));
    expect(
      tester.widget<DropdownButton<LudoAiDifficulty>>(difficultyPicker).value,
      LudoAiDifficulty.medium,
    );

    await tester.tap(difficultyPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('HARD').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<DropdownButton<LudoAiDifficulty>>(difficultyPicker).value,
      LudoAiDifficulty.hard,
    );

    final startAiMatch = find.byKey(const Key('start_ai_match'));
    await tester.ensureVisible(startAiMatch);
    await tester.pumpAndSettle();
    await tester.tap(startAiMatch);
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsOneWidget);
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
