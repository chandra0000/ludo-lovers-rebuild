import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_turn_resolution_guard.dart';

void main() {
  test('allows delayed action only for the captured match version', () {
    const guard = MatchTurnResolutionGuard(matchId: 'match-a', stateVersion: 3);
    expect(guard.matches(matchId: 'match-a', stateVersion: 3), isTrue);
    expect(guard.matches(matchId: 'match-a', stateVersion: 4), isFalse);
    expect(guard.matches(matchId: 'match-b', stateVersion: 3), isFalse);
  });
}
