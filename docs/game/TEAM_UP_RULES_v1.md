# Team Up — team-up@1

Owner-approved migration from legacy executable rules/tests on 2026-11-17.
Legacy geometry and engine architecture are not copied. Approved rebuild board,
route, safe cells and logical progress remain authoritative.

## Teams, movement and turns

Team A = Orange + Magenta. Team B = Green + Blue. Four seats/four pawns each.
Scheduled order remains Orange → Green → Magenta → Blue. Scheduled seat and active
recipient are separate immutable fields. A finished scheduled player transfers
to their unfinished teammate; a fully finished team's scheduled seats are skipped.
The scheduled seat advances only when the recipient's turn ends.

Six releases a yard pawn; movement and exact finish use the shared route. Six,
credited enemy captures and individual pawn finishes grant bonus turns. The third
consecutive six is forfeited without movement. An unfinished recipient retains a
bonus; finishing their fourth pawn transfers an eligible bonus to the unfinished
teammate. A six streak follows the scheduled bonus chain across such a transfer.
No Classic hard blockades or single-opponent landing restriction apply to Team Up;
its stack policy below replaces those policies without changing Classic.

## Unsafe stack policy

- Teammates are friendly and may share cells. Safe cells protect every occupant.
- An unequal opposing arrival leaves both teams present; last-arriving team owns
  immutable priority at that canonical shared-track cell.
- If a protected pawn departs while the priority team remains, every remaining
  protected-team pawn there returns to its yard; the mover is not captured.
- When the last priority-team pawn leaves, earlier occupants remain and priority
  clears. Partial departure retains priority while both teams remain.
- Equal team counts caused by an arrival award that cell to the arriving team;
  all opposing pawns return to their yards. Equality caused only by departure does
  not invoke this arrival rule. Membership/counts are by team, including stacks
  larger than two and mixed teammate colors.
- Priority is never guessed from animation order. Invalid/missing priority in a
  mixed unsafe restored cell is rejected.

Each returned pawn emits a typed TeamPawnCaptured event with capturing team,
victim/index and arrival/departure cause. The owner's explicit correction to the
legacy test is **no friendly-loss capture bonus**: protected departure losses are
credited to the opposing priority team, never the mover. Six/finish bonuses still
apply independently. The old Green-departs/Blue-lost extra-roll assertion is
intentionally replaced, not silently copied.

## Completion and persistence

A team wins only after all eight pawns finish. Both winning team and final finishing
player remain in state. A player's own fourth finish does not end an unfinished
team's game. Completion grants no further bonus.

Schema v4 Team Up snapshots additionally carry scheduledPlayer, priorityByCell
and winningTeam. Existing non-team snapshots remain valid without foreign team
state. Actor ownership follows the active recipient; command/version/idempotency
contracts remain MatchSession's responsibility.

The domain implementation is testable before UI availability. Public release and
physical/visual acceptance remain separate gates.
