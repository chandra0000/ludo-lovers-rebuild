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
