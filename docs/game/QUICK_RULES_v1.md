# Quick Mode — quick@1

Owner-approved objective (2026-11-17): first participating player to finish any two
of their four pawns wins immediately. All four pawns start in their yards. Players
choose which legal pawns to release/move; the objective does not preselect pawns.

Movement, release on six, exact finish, safe cells, single-opponent capture,
protected stacks, hard blockades, capture/finish/six bonuses and third-six forfeiture
match Classic v1. The terminal second finish emits completion and no extra turn.
Dice remain 1–6; there are no timers, loaded dice, shortened routes or geometry changes.

Use approved Classic fixed seats for 2/3/4 participants. Human/AI combinations,
seeded difficulty, names, restart and v4 save/resume retain this mode explicitly.
Compatibility and Classic remain unchanged and cannot be relabelled via mode data.
Public release remains gated; internal builds can exercise the real setup/game UI.

## Deterministic simulation evidence

`dart run tool/mode_duration_simulation.dart` uses 100 seeds per configuration,
medium legal AI, seed base 20261117, at most 10,000 rolls per match. All 600 games
completed; none hit the cap. Results are roll counts, not physical performance or
human minutes. Full sorted samples and runtime metadata are saved in
`docs/quality/evidence/quick-classic-roll-counts-2026-11-17.json`.

| Players | Classic median / p95 rolls | Quick median / p95 rolls |
| --- | ---: | ---: |
| 2 | 175 / 224 | 98 / 143 |
| 3 | 326 / 480 | 180 / 299 |
| 4 | 539 / 835 | 255 / 519 |

This observed reduction applies to the documented deterministic policy/seeds.
Real match duration depends on human decisions and presentation pacing.
