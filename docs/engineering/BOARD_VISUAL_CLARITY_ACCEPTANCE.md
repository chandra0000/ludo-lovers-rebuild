# Board visual clarity — acceptance and rollout

## Design decision
Preserve the approved glass-board source and exact board crop, pawn mapping,
existing logo, avatars, 3D dice, local chat and reactions. Do **not** regenerate
the logo or board without a side-by-side, owner-approved alternative.

## Changes in this stacked PR
- Add a decorative gold boundary around, not over, the board's exact crop.
- Improve current-turn readability with a two-line high-contrast HUD, a
  player-colored outline and a screen-reader live announcement.
- Keep board/pawn hit testing and 576×1024 canvas coordinates unchanged.

## Acceptance gates
1. The 15×15 board and all pawn anchor coordinates must remain unchanged.
2. The frame must be outside the rendered board and IgnorePointer.
3. Widget tests and Android builds must pass on the new branch.
4. Review fresh 393×873 and 393×699 screenshot artifacts side by side.
5. Test on 6.1–6.9-inch physical phones for pawn taps, readability, safe areas,
   chat keyboard, TalkBack, 20-minute gameplay and thermal performance.
6. Measure frame timing and memory before claiming improved performance.
7. Do not merge this stacked PR before its base PR #34 is accepted.

## Pending design work
- Verify the user-uploaded Canva logo against the approved bundled logo.
- Compare an original *derived* full-board visual composition against the
  current cropped board, retaining the canonical source unchanged.
- Produce owner-approved home/mode/win/rematch design variants before coding.
- Confirm 2-player, 4-player, and bot seating copy across all modes.
