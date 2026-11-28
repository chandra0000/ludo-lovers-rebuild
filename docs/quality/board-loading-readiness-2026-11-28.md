# Board loading regression follow-up

Baseline: PR114 head fd0ec262dee25cbb0e1deaa0fb553be89a22392e, after main
ef335c871fda69e63404fa47c84c7a743bdb62b2. This follow-up depends on114;
it does not replace the accepted royal UI or bring older branches forward.

## Observations and established cause

The actual430x932 Android recording from run46124211090 was reviewed again,
including four samples per second through entry/loading and denser movement/capture
frames. It shows the loading panel before the board and logo are decoded. This is
not evidence of an application crash. The prior four-second contact sheets were
insufficient to assess this short transition.

MatchBoardArtwork already hid pawn overlays before its decoded frame, but did not
report readiness to MatchScreen. The screen enabled human dice, scheduled AI and
resolved saved rolls independently of image readiness. On sufficiently slow decode,
authoritative commands and animations could therefore advance behind the loading
panel. This is a reproducible orchestration gap, not a change to engine legality.

The preparing label used26 reference-canvas pixels, shrinking with the board; it
was less readable than the independent HUD. The header also advertised Roll dice
before the artwork was ready.

## Focused correction

- Artwork emits deduplicated readiness after paint, guarded against stale callbacks
  and disposal. Provider replacement cannot keep gapless old artwork behind new
  overlays. Image errors retain the existing retry UI and report not-ready.
- MatchScreen gates human/AI/automatic actions on readiness, cancels pending
  resolution/AI work when unavailable, and resumes the already accepted turn once
  ready without generating another roll. The dice readiness pulse is gated;
  the compact header says Preparing board until ready. Navigation remains usable.
- Loading text uses bundled Nunito and inverse canvas sizing for16 logical pixels,
  respects system scaling and wraps without overflowing the board region.
- Existing interaction tests and recording fixtures await the real decoded frame
  and post-paint HUD update, rather than clicking during loading. No assertion,
  rule, timeout or test was removed to make checks pass.

## Verification scope

Eight focused tests cover human input during slow decode, AI's450ms delay starting
only after readiness, restored-six single execution, disposal before decode, and
four mandatory sizes with200% actual text scaling. Real Flutter loading PNGs are
saved under test-artifacts/acceptance/board-loading-*-2x.png, with deliberately
pending artwork. These are loading fixtures, not replacement-board screenshots.
Existing recovery, geometry, pixel protection, movement, AI, replay and save tests
remain required. Fresh native recording and default-renderer checkpoint must verify
the resulting head; historical114 clips do not prove this fix.

Approved board/logo bytes, geometry, pawns, dice, rules and saved schemas remain
unchanged. Physical60fps/performance/audio/haptics, owner visual approval and release
signing remain separate gates. This report does not assert every possible visual
issue or production readiness is resolved.
