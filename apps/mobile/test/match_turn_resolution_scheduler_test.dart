import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_turn_resolution_scheduler.dart';

void main() {
  test('cancel prevents a stale turn callback', () async {
    final scheduler = MatchTurnResolutionScheduler();
    var calls = 0;
    scheduler.schedule(const Duration(milliseconds: 10), () => calls++);
    scheduler.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 0);
  });

  test('new turn supersedes a pending callback', () async {
    final scheduler = MatchTurnResolutionScheduler();
    var oldCalls = 0;
    var newCalls = 0;
    scheduler.schedule(const Duration(milliseconds: 10), () => oldCalls++);
    scheduler.schedule(const Duration(milliseconds: 10), () => newCalls++);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(oldCalls, 0);
    expect(newCalls, 1);
  });
}
