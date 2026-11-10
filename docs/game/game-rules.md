# Game rules — current provisional profile

This document records the rules currently encoded in the first engine. It is not a claim that every rule has received product sign-off.

## Players and turns

- Four players: Orange, Green, Magenta, Blue.
- Turn order: Orange → Green → Magenta → Blue → Orange.
- Four pawns per player.
- A pawn at progress `-1` is in its yard.
- A pawn must roll a six to leave its yard.
- A six grants another turn in the current implementation.
- A capture grants another turn in the current implementation.

## Track and finish

- Shared physical track: 52 cells.
- Player-relative shared-track progress: 0 through 50 (51 positions).
- Home lane: five cells (progress 51 through 55).
- Finish/home center: progress 56.
- A move that would exceed 56 is illegal.
- Safe shared-track IDs currently encoded: 0, 8, 13, 21, 26, 34, 39, 47.

## Captures

The current engine sends an opponent pawn back to its yard when a pawn lands on the same non-safe shared-track cell. Pawns in home lanes are not captured.

## Important pending rule decisions

Before calling the rules release-ready, confirm:
- Whether the intended variant grants an extra turn on every six and on capture.
- Exact safe-cell/star locations on the approved board.
- Whether multiple pawns may share a cell and how blockades behave.
- Whether a six is required to start and whether three consecutive sixes have a penalty.
- Exact finish rule and whether an exact roll is required.
- Team/2-player variants are out of scope for the first milestone.

Change the engine and this document together whenever the rules profile is approved or revised.


## Compatibility requirements carried forward from the original repository

The legacy rule specification records the following proposed Classic defaults. They remain **pending product acceptance** and must be implemented through a named/versioned domain rule profile, not widget conditionals:

- Three consecutive sixes end the turn; the third six cannot move a pawn.
- Reaching final home grants one extra roll.
- If a move satisfies more than one bonus condition, bonuses do not stack into multiple immediate rolls.
- Own-pawn stacking is an explicit profile choice; opponent stacking/blockades must have explicit, tested semantics.
- A player who has finished all pawns is skipped; winner-takes-all versus placement-mode match completion is mode-specific.
- Domain transitions should emit typed events with deterministic sequence/state-version metadata. A rejected or stale command must not mutate state.

## Current implementation gaps (confirmed by source review)

The current `LudoGame` is a small immutable-state model, not yet the legacy typed transition engine:
- It currently grants a bonus for six and capture, but does not grant a finish bonus.
- It does not track consecutive sixes.
- It hard-codes rules and safe cells rather than consuming an immutable, named/versioned rule profile.
- It has no typed command/event/error stream, expected-state-version guard, idempotency key, or deterministic replay contract.
- Capture currently returns opponent pawns on an unsafe shared-track cell to the yard. Advanced blockade/stack policies are not implemented.
- The current engine's progress model is 0–50 on the player's 51 traversed shared positions, 51–55 on five private lane cells, and 56 at the separate centre finish. This is consistent with the legacy five-lane-plus-centre decision; do not reinterpret it as 52 player-relative steps.

Do not silently change any of these behaviours. Implement the missing rules only after the product owner confirms the intended Classic profile. The route and safe-cell constants are also still provisional pending visual board approval.
