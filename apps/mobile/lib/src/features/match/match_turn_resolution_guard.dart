/// Captures the authoritative match identity when a delayed UI action starts.
/// A delayed action must not apply to a newer match or state version.
class MatchTurnResolutionGuard {
  const MatchTurnResolutionGuard({
    required this.matchId,
    required this.stateVersion,
  });

  final String matchId;
  final int stateVersion;

  bool matches({required String matchId, required int stateVersion}) {
    return this.matchId == matchId && this.stateVersion == stateVersion;
  }
}
