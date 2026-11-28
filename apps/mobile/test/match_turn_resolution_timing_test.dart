import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_turn_resolution_timing.dart';

void main() {
  test('automatic move and pass timings match approved snappy pacing', () {
    const timing = MatchTurnResolutionTiming();
    expect(timing.automaticPawn, const Duration(milliseconds: 180));
    expect(timing.passTurn, const Duration(milliseconds: 650));
  });
}
