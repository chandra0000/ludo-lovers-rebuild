/// Presentation-only turn resolution delays; game rules remain in MatchSession.
class MatchTurnResolutionTiming {
  const MatchTurnResolutionTiming();

  Duration get passTurn => const Duration(milliseconds: 550);
  Duration get automaticPawn => const Duration(milliseconds: 350);
}
