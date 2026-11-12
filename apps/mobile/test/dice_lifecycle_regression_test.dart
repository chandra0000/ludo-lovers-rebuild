import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';

void main() {
  testWidgets('new roll settles once and cannot be requested twice', (
    tester,
  ) async {
    var requests = 0;
    var completions = 0;
    var value = 0;
    var rollId = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) {
            return LuxuryDiceButton(
              targetValue: value == 0 ? null : value,
              rollId: rollId,
              canRoll: value == 0,
              isWaitingForRoll: value == 0,
              onRollRequested: () {
                requests++;
                update(() {
                  value = 6;
                  rollId++;
                });
              },
              onAnimationComplete: () => completions++,
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.pump();
    await tester.tap(find.byType(LuxuryDiceButton));
    expect(requests, 1);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, 1);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, 1);
    expect(find.bySemanticsLabel('Dice, value 6'), findsOneWidget);
  });

  testWidgets('disposing during tumble never calls completion', (
    tester,
  ) async {
    var completions = 0;
    var rollId = 0;
    int? value;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) {
            return LuxuryDiceButton(
              targetValue: value,
              rollId: rollId,
              canRoll: value == null,
              isWaitingForRoll: value == null,
              onRollRequested: () {
                update(() {
                  value = 2;
                  rollId++;
                });
              },
              onAnimationComplete: () => completions++,
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 800));
    expect(completions, 0);
    expect(tester.takeException(), isNull);
  });
}
