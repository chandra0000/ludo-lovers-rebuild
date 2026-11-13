import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_ai_scheduler.dart';

void main() {
  test('only one pending AI callback is scheduled', () async {
    final scheduler = MatchAiScheduler();
    var calls = 0;
    scheduler.schedule(() => calls++);
    scheduler.schedule(() => calls++);
    expect(scheduler.isScheduled, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(calls, 1);
    expect(scheduler.isScheduled, isFalse);
  });

  test('cancelling prevents a callback from an old match', () async {
    final scheduler = MatchAiScheduler();
    var calls = 0;
    scheduler.schedule(() => calls++);
    scheduler.cancel();
    expect(scheduler.isScheduled, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(calls, 0);
  });
}
