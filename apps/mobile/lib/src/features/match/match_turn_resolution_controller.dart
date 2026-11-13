import 'match_turn_resolution_guard.dart';
import 'match_turn_resolution_scheduler.dart';
import 'match_turn_resolution_timing.dart';

/// Coordinates delayed automatic turns without owning gameplay rules.
///
/// The authoritative MatchSession still decides whether a pawn may move or
/// whether a pass is allowed. This controller only owns pending state, delay
/// policy and rejection of callbacks targeting an obsolete match version.
class MatchTurnResolutionController {
  MatchTurnResolutionController({
    MatchTurnResolutionScheduler? scheduler,
    MatchTurnResolutionTiming timing = const MatchTurnResolutionTiming(),
  })  : _scheduler = scheduler ?? MatchTurnResolutionScheduler(),
        _timing = timing;

  final MatchTurnResolutionScheduler _scheduler;
  final MatchTurnResolutionTiming _timing;
  bool _isPending = false;

  bool get isPending => _isPending;

  void schedulePass({
    required String matchId,
    required int stateVersion,
    required String Function() currentMatchId,
    required int Function() currentStateVersion,
    required bool Function() canExecute,
    required void Function() onReady,
  }) {
    _schedule(
      _timing.passTurn,
      matchId: matchId,
      stateVersion: stateVersion,
      currentMatchId: currentMatchId,
      currentStateVersion: currentStateVersion,
      canExecute: canExecute,
      onReady: onReady,
    );
  }

  void schedulePawn({
    required String matchId,
    required int stateVersion,
    required String Function() currentMatchId,
    required int Function() currentStateVersion,
    required bool Function() canExecute,
    required void Function() onReady,
  }) {
    _schedule(
      _timing.automaticPawn,
      matchId: matchId,
      stateVersion: stateVersion,
      currentMatchId: currentMatchId,
      currentStateVersion: currentStateVersion,
      canExecute: canExecute,
      onReady: onReady,
    );
  }

  void _schedule(
    Duration delay, {
    required String matchId,
    required int stateVersion,
    required String Function() currentMatchId,
    required int Function() currentStateVersion,
    required bool Function() canExecute,
    required void Function() onReady,
  }) {
    final guard = MatchTurnResolutionGuard(
      matchId: matchId,
      stateVersion: stateVersion,
    );
    _isPending = true;
    _scheduler.schedule(delay, () {
      _isPending = false;
      if (!guard.matches(
        matchId: currentMatchId(),
        stateVersion: currentStateVersion(),
      )) {
        return;
      }
      if (!canExecute()) return;
      onReady();
    });
  }

  void cancel() {
    _scheduler.cancel();
    _isPending = false;
  }
}
