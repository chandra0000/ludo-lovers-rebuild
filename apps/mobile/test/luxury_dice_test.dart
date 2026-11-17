import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';

void main() {
  testWidgets('each authoritative result faces the camera on the 3D cube',
      (tester) async {
    for (var value = 1; value <= 6; value++) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('dice_result_$value'),
          home: Center(
            child: LuxuryDiceButton(
              targetValue: value,
              rollId: value,
              canRoll: false,
              isWaitingForRoll: false,
              onRollRequested: _noop,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('six_face_dice_cube')), findsOneWidget);
      expect(find.byKey(Key('dice_face_$value')), findsOneWidget);
      final faces = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byKey(const Key('six_face_dice_cube')),
              matching: find.byType(Transform),
            ),
          )
          .where(
            (transform) =>
                transform.child?.key.toString().contains('dice_face_') ?? false,
          );
      expect(faces.last.child!.key, Key('dice_face_$value'));
      expect(faces.length, greaterThan(1));
    }
  });

  testWidgets('enabling reduced motion mid-roll settles the same result once',
      (tester) async {
    var reduce = false;
    var rollId = 0;
    int? value;
    var completions = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
              child: LuxuryDiceButton(
                targetValue: value,
                rollId: rollId,
                canRoll: value == null,
                isWaitingForRoll: value == null,
                onRollRequested: () => setState(() {
                  value = 6;
                  rollId++;
                }),
                onAnimationComplete: () => completions++,
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(completions, 0);
    update(() => reduce = true);
    await tester.pump();
    await tester.pump();
    expect(completions, 1);
    expect(value, 6);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, 1);
    expect(find.bySemanticsLabel('Dice, value 6'), findsOneWidget);
  });

  testWidgets('restored dice result is displayed without replaying a roll',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LuxuryDiceButton(
          targetValue: 5,
          rollId: 8,
          canRoll: false,
          isWaitingForRoll: false,
          onRollRequested: () {},
          onAnimationComplete: () => completed++,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(completed, 0);
    expect(
      tester
          .widget<LuxuryDiceButton>(find.byType(LuxuryDiceButton))
          .targetValue,
      5,
    );
  });

  testWidgets('a new rollId animates even when the face repeats',
      (tester) async {
    var completed = 0;
    var requests = 0;
    var rollId = 1;
    int? target = 4;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              LuxuryDiceButton(
                targetValue: target,
                rollId: rollId,
                canRoll: target == null,
                isWaitingForRoll: target == null,
                onRollRequested: () {
                  requests++;
                  setState(() {
                    target = 4;
                    rollId++;
                  });
                },
                onAnimationComplete: () => completed++,
              ),
              TextButton(
                onPressed: () => setState(() => target = null),
                child: const Text('next turn'),
              ),
            ],
          ),
        ),
      ),
    );

    // The previous result is cleared, then the next accepted roll returns 4
    // again. The incremented rollId must still trigger a fresh animation.
    await tester.tap(find.text('next turn'));
    await tester.pump();
    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.pump();
    expect(requests, 1);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completed, 1);
  });

  testWidgets('reduced motion completes exactly once after the frame',
      (tester) async {
    var completed = 0;
    var target = 0;
    var rollId = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) => LuxuryDiceButton(
              targetValue: target == 0 ? null : target,
              rollId: rollId,
              canRoll: target == 0,
              isWaitingForRoll: target == 0,
              onRollRequested: () {
                setState(() {
                  target = 6;
                  rollId++;
                });
              },
              onAnimationComplete: () => completed++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(completed, 1);
  });

  testWidgets('clearing a dice result cancels its pending completion',
      (tester) async {
    var completed = 0;
    var target = 0;
    var rollId = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              LuxuryDiceButton(
                targetValue: target == 0 ? null : target,
                rollId: rollId,
                canRoll: target == 0,
                isWaitingForRoll: target == 0,
                onRollRequested: () {
                  setState(() {
                    target = 3;
                    rollId++;
                  });
                },
                onAnimationComplete: () => completed++,
              ),
              TextButton(
                onPressed: () => setState(() => target = 0),
                child: const Text('clear'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(completed, 0);
  });

  testWidgets('rejects taps when disabled or outside the roll phase',
      (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            LuxuryDiceButton(
              targetValue: null,
              rollId: 0,
              canRoll: false,
              isWaitingForRoll: true,
              onRollRequested: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(LuxuryDiceButton));
    expect(requests, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: LuxuryDiceButton(
          targetValue: null,
          rollId: 0,
          canRoll: true,
          isWaitingForRoll: false,
          onRollRequested: () => requests++,
        ),
      ),
    );
    await tester.tap(find.byType(LuxuryDiceButton));
    expect(requests, 0);
  });

  testWidgets('prevents duplicate requests before the engine responds',
      (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LuxuryDiceButton(
          targetValue: null,
          rollId: 0,
          canRoll: true,
          isWaitingForRoll: true,
          onRollRequested: () => requests++,
        ),
      ),
    );

    await tester.tap(find.byType(LuxuryDiceButton));
    await tester.tap(find.byType(LuxuryDiceButton));
    expect(requests, 1);
  });
}

void _noop() {}
