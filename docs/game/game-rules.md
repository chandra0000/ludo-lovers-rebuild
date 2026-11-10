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


## Versioned rule profiles and transition contract

The rebuild now exposes immutable, named profiles:

- `ludo-lovers-current@1` is the default compatibility profile. It preserves the existing six/capture bonus behaviour and does not add finish bonuses or a three-sixes penalty.
- `classic@1` is an opt-in proposed profile based on the legacy Classic defaults. It adds a finish bonus and makes the third consecutive six consume the roll and pass the turn without moving a pawn.

The Classic profile is deliberately **not the default**. Its rule choices, safe-cell identity, and stack/blockade semantics remain pending product acceptance. Do not silently switch an existing match or new match to Classic.

Every accepted roll, pass, or pawn move increments the immutable game `stateVersion` exactly once. Callers may supply `expectedStateVersion` to reject stale actions and a unique `commandId` to reject duplicate submissions. Each transition exposes an immutable, deterministically ordered typed event list; every event carries its sequence number and resulting state version. Current event types cover dice rolls, pawn movement, captures, turn changes, the consecutive-six penalty, and wins.

The game snapshots and player pawn-progress lists are immutable. Rejected commands throw before producing a new state and therefore cannot partially mutate the prior snapshot. Command IDs are retained in the versioned local snapshot for in-match idempotency. Local save/resume across process restarts is implemented; durable event replay and a full transition history are still not implemented.

## Gameplay regression coverage added

The automated suite now exercises capture from all four seat orientations and checks every configured safe-cell ID against a live capture attempt. The default compatibility profile also has an explicit exact-finish/overshoot test: a pawn at progress 55 may finish on a roll of one, while a roll of two cannot move it and passes the turn. These tests verify the currently encoded behaviour; they do not silently select the opt-in Classic profile or resolve pending blockade/stack product decisions.

## Remaining implementation gaps

Remaining implementation gaps:
- The engine currently exposes typed events but still uses direct `roll`, `movePawn`, and `passTurn` methods rather than a closed typed command/result/error API.
- State versions and command IDs protect in-memory transitions, but durable idempotency, serialized snapshots, deterministic replay, and event history across process restarts are not implemented.
- Capture currently returns opponent pawns on an unsafe shared-track cell to the yard. Advanced blockade/stack policies are not implemented.
- The current progress model is 0–50 on the player's 51 traversed shared positions, 51–55 on five private lane cells, and 56 at the separate centre finish. This is consistent with the legacy five-lane-plus-centre decision; do not reinterpret it as 52 player-relative steps.
- Player elimination/skip logic and match-completion modes beyond winner-takes-all remain unimplemented.

Do not silently change the default compatibility profile. The proposed Classic profile remains opt-in until the product owner accepts it. The route and safe-cell constants are also still provisional pending visual board approval.

## Critical correctness review — 2026-11-10

Two defects found during the Classic acceptance review have been fixed:

- Snapshot validation now applies the two-six maximum only to profiles that enforce the three-consecutive-six penalty. The compatibility profile does not impose that penalty and can legitimately retain a higher consecutive-six count; its local snapshot must still restore.
- The match coordinator now treats a Classic third-six penalty as an immediate turn transition with no pending dice animation. It schedules the next AI seat instead of leaving the match in a permanent dice-animation state.

Regression tests cover compatibility-profile snapshot restoration after three consecutive sixes, rejection of an invalid Classic snapshot counter, and a human third-six penalty handing control to an AI seat.

The remaining release blockers are product decisions and visual/device evidence, not assumptions to be silently encoded:

- Confirm own-pawn stacking and opponent blockade rules, including whether a blockade prevents passing and how it is captured.
- Confirm the exact safe-star cells against the canonical artwork.
- Confirm the intended match completion mode after the first player wins.
- Obtain product-owner acceptance of the Classic profile before making it the default.

