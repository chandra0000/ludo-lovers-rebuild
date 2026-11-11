# Team Up mode implementation plan

Status: **planned; not exposed in the app**. This work is tracked by issue
[#19](https://github.com/chandra0000/ludo-lovers-rebuild/issues/19) and is
based on the legacy repository's `docs/team-up-mode-acceptance.md`.

## Product contract

- Team A: Orange + Magenta.
- Team B: Green + Blue.
- Scheduled seat order is fixed: Orange → Green → Magenta → Blue.
- A scheduled seat that has finished all four pawns transfers its scheduled
  turn to its unfinished teammate. The scheduled seat and active recipient
  must be represented separately in immutable state.
- The active recipient keeps six/capture/finish bonuses. If that recipient
  finishes their fourth pawn and earns a bonus, the bonus transfers to their
  unfinished teammate. The scheduled seat advances only when that turn ends.
- Teammates can share unsafe cells and can never capture each other. Safe
  squares protect all pawns.
- On an unsafe mixed-team cell, the last-arriving team owns capture priority.
  Mixed occupants remain until a departure or equal-stack resolution changes
  the cell state. Priority must be stored in the game snapshot, not inferred
  from widget order or animation timing.
- When the protected team departs while the priority team remains, all other
  protected-team pawns at that cell are captured; the departing pawn is not.
  If the priority team leaves first, the other team remains and the priority
  record is cleared. Equal team counts immediately resolve in favour of the
  last-arriving team.
- A team wins only when all eight of its pawns have finished. Preserve both
  the winning team and the last player to finish for the result UI.

## Domain design constraints

1. Extend the existing immutable `LudoGame`; do not create a second Team Up
   movement/capture engine.
2. Add a distinct versioned Team Up rule profile/mode. Keep
   `ludo-lovers-current@1` as the existing default and preserve Classic
   behavior and snapshots.
3. Model `scheduledPlayer` separately from `activePlayer`.
4. Persist mixed-cell capture priority by physical shared-track cell and team.
   Validate that every priority record references an unsafe shared-track cell
   containing both teams and that its priority team is present.
5. Use one turn resolver for normal turn advancement, finished-seat transfer,
   bonus retention and third-six handling. Do not implement turn rules in UI.
6. Extend the snapshot schema with explicit migration for existing schemas.
   Existing saved matches must retain their previous profile and semantics.
7. Keep the existing `MatchSession` command boundary as the only application
   entry point for roll, move and pass. Replays must reproduce priority state,
   winner metadata and ordered capture events.

## Required engine test matrix

- Fixed team membership and scheduled order.
- Transfer from a finished scheduled seat to its unfinished teammate.
- Skip a team only after both teammates finish.
- Bonus six/capture stays with the active recipient.
- Finish bonus transfers from a newly finished active player to the teammate.
- Scheduled seat advances only when the transferred/bonus turn ends.
- Teammate stacks remain friendly on unsafe cells.
- Safe cells protect both teams.
- Last-arrival priority is persisted and survives snapshot round-trip.
- Protected-team departure captures every remaining protected pawn but not
  the pawn that departed.
- Priority-team departure clears priority without capturing the other team.
- Equal-sized mixed stacks resolve in favour of the last-arriving team.
- Three-or-more-pawn mixed stacks resolve deterministically by team count.
- Team A and Team B win only after all eight pawns finish.
- Snapshot migration preserves all pre-Team-Up profile behavior.
- Command replay reproduces state, priority records and event order.

## UI and release gate

- Keep Team Up disabled in setup until the complete engine, session, snapshot,
  navigation, widget and integration test matrix passes.
- Add an explicit team identity banner, scheduled-seat/active-recipient
  indicator and team result panel.
- Keep the canonical board image and existing geometry unchanged.
- Run the Android emulator navigation smoke test, then complete physical-device
  gameplay, touch, accessibility and performance acceptance separately.
- Do not describe Team Up as shipped or release-approved before owner/device
  acceptance is recorded.
