import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/animated_dice.dart';

void main() {
  testWidgets('reveals the engine dice value with a bounded roll animation', (tester) async {
    var value = 0;
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 90,
                height: 90,
                child: AnimatedDice(
                  value: value == 0 ? null : value,
                  onTap: () => setState(() => value = 5),
                  onRollCompleted: () => completed = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnimatedDice));
    await tester.pump();
    expect(value, 5);
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 800));
    expect(completed, isTrue);
    expect(tester.widget<AnimatedDice>(find.byType(AnimatedDice)).value, 5);
  });

  testWidgets('does not invoke roll callback while disabled', (tester) async {
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 90,
          height: 90,
          child: AnimatedDice(
            value: null,
            enabled: false,
            onTap: () => rolls++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AnimatedDice));
    expect(rolls, 0);
  });
  testWidgets('skips the dice animation when reduced motion is enabled',
      (tester) async {
    var value = 0;
    var completed = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Center(
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: AnimatedDice(
                    value: value == 0 ? null : value,
                    onTap: () => setState(() => value = 4),
                    onRollCompleted: () => completed = true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnimatedDice));
    await tester.pump();
    await tester.pump();
    expect(value, 4);
    expect(completed, isTrue);
  });

}
