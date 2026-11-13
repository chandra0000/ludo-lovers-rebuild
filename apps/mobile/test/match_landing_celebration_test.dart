import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_landing_celebration.dart';
import 'package:ludo_lovers/src/features/match/match_move_presentation_plan.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('accepted move produces a decorative landing pulse',
      (tester) async {
    final plan = MatchMovePresentationPlan.fromEvents(
      player: PlayerColor.orange,
      pawnIndex: 0,
      events: [
        const PawnMoved(1, 1, PlayerColor.orange, 0, 0, 1),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 576,
            height: 1024,
            child: Stack(children: [MatchLandingCelebration(plan: plan)]),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('pawn_landing_fx')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
