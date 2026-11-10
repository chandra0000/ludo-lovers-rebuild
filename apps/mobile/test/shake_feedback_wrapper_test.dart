import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/shake_feedback_wrapper.dart';

void main() {
  testWidgets(
    'shake feedback animates without replacing its child',
    (tester) async {
    final key = GlobalKey<ShakeFeedbackWrapperState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShakeFeedbackWrapper(
            key: key,
            child: const SizedBox(
              key: Key('pawn_visual'),
              width: 30,
              height: 36,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('pawn_visual')), findsOneWidget);
    key.currentState!.triggerShake();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('pawn_visual')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('pawn_visual'))),
      const Size(30, 36),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
