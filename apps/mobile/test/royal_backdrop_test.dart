import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/royal_backdrop.dart';
import 'package:ludo_lovers/src/features/match/royal_game_header.dart';
import 'package:ludo_lovers/src/features/match/royal_crown.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
        'backdrop fills screen, does not absorb taps or schedule frames; reduced=$reduced',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: RoyalBackdrop(
              child: Center(
                child: FilledButton(
                  onPressed: () => taps++,
                  child: const Text('Tap'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('royal_backdrop'))),
        tester.view.physicalSize / tester.view.devicePixelRatio,
      );
      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.binding.transientCallbackCount, 0);
      final painted = find.descendant(
        of: find.byKey(const Key('royal_backdrop')),
        matching: find.byType(CustomPaint),
      );
      final painter = tester.widget<CustomPaint>(painted).painter!;
      expect(painter.shouldRepaint(painter), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('header crown stays small and square beside the approved logo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 84,
            child: Center(child: RoyalBrandMark(size: 72)),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(RoyalCrown)), const Size(16, 16));
    expect(
      tester.getSize(find.byKey(const Key('match_brand_mark'))),
      const Size(72, 72),
    );
    expect(tester.takeException(), isNull);
  });
}
