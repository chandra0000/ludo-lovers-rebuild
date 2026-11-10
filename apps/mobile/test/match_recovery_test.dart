import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('restored pending AI roll passes without getting stranded',
      (tester) async {
    final pendingAiTurn = LudoGame.initial().roll(2);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: pendingAiTurn,
          aiPlayers: const {PlayerColor.orange},
          aiSeed: 42,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
