import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_turn_resolution_controller.dart';
import 'package:ludo_lovers/src/features/match/match_turn_resolution_timing.dart';

class _FastTiming extends MatchTurnResolutionTiming {
  const _FastTiming();

  @override
  Duration get automaticPawn => const Duration(milliseconds: 10);

  @override
  Duration get passTurn => const Duration(milliseconds: 10);
}

void main() {
  MatchTurnResolutionController create() {
    return MatchTurnResolutionController(timing: const _FastTiming());
  }

  test('eligible pawn callback runs once and releases pending state', () async {
    final controller = create();
    var calls = 0;
    controller.schedulePawn(
      matchId: 'match-a',
      stateVersion: 1,
      currentMatchId: () => 'match-a',
      currentStateVersion: () => 1,
      canExecute: () => true,
      onReady: () => calls++,
    );
    expect(controller.isPending, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(controller.isPending, isFalse);
    expect(calls, 1);
  });

  test('stale state and a different match are never auto-passed', () async {
    final controller = create();
    var version = 1;
    var calls = 0;
    controller.schedulePass(
      matchId: 'match-a',
      stateVersion: 1,
      currentMatchId: () => 'match-a',
      currentStateVersion: () => version,
      canExecute: () => true,
      onReady: () => calls++,
    );
    version = 2;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 0);
    expect(controller.isPending, isFalse);

    controller.schedulePass(
      matchId: 'match-a',
      stateVersion: 2,
      currentMatchId: () => 'match-b',
      currentStateVersion: () => version,
      canExecute: () => true,
      onReady: () => calls++,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 0);
    expect(controller.isPending, isFalse);
  });

  test('cancel on restart or background invalidates pending work', () async {
    final controller = create();
    var calls = 0;
    controller.schedulePawn(
      matchId: 'match-a',
      stateVersion: 1,
      currentMatchId: () => 'match-a',
      currentStateVersion: () => 1,
      canExecute: () => true,
      onReady: () => calls++,
    );
    controller.cancel();
    expect(controller.isPending, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 0);
  });

  test('rechecks eligibility before executing a delayed turn', () async {
    final controller = create();
    var foreground = true;
    var calls = 0;
    controller.schedulePass(
      matchId: 'match-a',
      stateVersion: 1,
      currentMatchId: () => 'match-a',
      currentStateVersion: () => 1,
      canExecute: () => foreground,
      onReady: () => calls++,
    );
    foreground = false;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 0);
    expect(controller.isPending, isFalse);
  });
}
