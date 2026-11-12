import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_turn_resolution_timing.dart';

void main() {
  test('automatic move and pass timings remain unchanged', () {
    const timing = MatchTurnResolutionTiming();
    expect(timing.automaticPawn, const Duration(milliseconds: 350));
    expect(timing.passTurn, const Duration(milliseconds: 600));
  });
}
