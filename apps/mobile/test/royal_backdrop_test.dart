import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/royal_backdrop.dart';

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
}
