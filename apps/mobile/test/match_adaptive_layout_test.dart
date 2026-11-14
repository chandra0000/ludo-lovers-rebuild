import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_adaptive_layout.dart';

void main() {
  const canvas = Size(576, 1024);

  test('board stage never crops or stretches on common portrait sizes', () {
    for (final phone in const [
      Size(320, 640),
      Size(360, 800),
      Size(393, 873),
      Size(430, 932),
      Size(440, 956),
    ]) {
      final layout = MatchAdaptiveLayout.resolve(
        available: phone,
        canvas: canvas,
      );
      expect(layout.stageSize.width, lessThanOrEqualTo(phone.width + .001));
      expect(layout.stageSize.height, lessThanOrEqualTo(phone.height + .001));
      expect(layout.stageSize.width / layout.stageSize.height,
          closeTo(canvas.width / canvas.height, .00001));
      expect(layout.freeTop, greaterThanOrEqualTo(0));
      expect(layout.freeBottom, greaterThanOrEqualTo(0));
    }
  });

  test('short phones use compact presentation metrics', () {
    final compact = MatchAdaptiveLayout.resolve(
      available: const Size(320, 640),
      canvas: canvas,
    );
    expect(compact.compact, isTrue);
    final standard = MatchAdaptiveLayout.resolve(
      available: const Size(393, 873),
      canvas: canvas,
    );
    expect(standard.compact, isFalse);
  });

  test('tall phones expose symmetric space for independent HUD rails', () {
    final layout = MatchAdaptiveLayout.resolve(
      available: const Size(393, 950),
      canvas: canvas,
    );
    expect(layout.freeTop, closeTo(layout.freeBottom, .00001));
    expect(layout.stageSize.height + layout.freeTop + layout.freeBottom,
        closeTo(950, .00001));
  });
}
