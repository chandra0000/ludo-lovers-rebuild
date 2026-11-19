# Responsive profiles and centered logo — 2026-11-19

## Approved direction and scope

The owner's latest feedback moves the approved application logo between the top
profiles, mirroring the bottom dice placement, enlarges player profiles/avatars
according to available screen space, reduces social icon prominence and refines
the royal background. This supersedes the previous separate logo header row.
The implementation follows unmerged evidence PR #72; nothing is merged automatically.

One live GameBoardScaffold still serves all local configurations. Orange and Green
flank RoyalBrandMark; Blue and Magenta flank the existing authoritative gold die.
Both middle regions share one width and centerline. Navigation remains a separate
48dp safe-area control row; team scores retain their existing state-driven strip.

## Implementation

- Profile rows scale from 108dp compact to 140dp on spacious screens, with an
  additional 24dp allowance for enlarged text. Square avatars scale with both row
  height and actual card width (about 55–76dp on the required default-text phones,
  previously 40dp); width calculation reserves padding, borders and 48dp social rail.
- Logo scales 56–88dp inside the same central column as the dice. The original image
  bytes, accessible label, bounded gold glow and crown are reused.
- Chat/emoji glyphs reduce 28→20dp. Each independent interaction stays 48×48dp with
  named local-only tooltips; inactive slots remain noninteractive.
- RoyalBackdrop adds a fine low-opacity woven diamond texture, warmer top lighting
  and a richer purple/midnight gradient. It remains static, cached, pointer-excluded
  and reduced-motion safe, with no new animation loop or blur filter.
- Approved board/logo assets, uniform board transform, pawn anchors, safe stars,
  brand identity, engine scheduling, mode profiles and persistence are unchanged.

## Verification and diagnostics

Focused regression checks pass, including exact isolated/composited board pixels,
mode-aware slots, social targets/lifecycle and all required responsive viewports.
The compact first attempt exposed a 1.12dp horizontal avatar squeeze from border
and padding constraints; explicitly reserving that space restores exact squares.
No test was disabled. Static analysis with fatal infos passes.

New assertions require the logo's bounds to fall between the top cards at their
vertical center, avatars to be at least 52dp across the required captures, profiles
and avatars to grow on larger screens, and social icons 20dp with 48dp targets.
The existing no-overflow, enlarged-text, safe-area, color identity and board bounds
assertions remain active.

Actual Flutter captures at 320×640 and 393×873 were inspected: larger avatars,
centered logo, smaller icons and full board are visible. The screenshot suite also
covers 360×800,430×932 and additional compact/tall/tablet/DPR/safe-area cases.
All 446 tests pass locally (152s). Strict formatting of 188 Dart files and
`flutter analyze --no-pub --fatal-infos` pass. All 36 required software PNGs
validate; all generated PNGs were fully decoded with Pillow. CI/build/native
conclusions are recorded separately in the PR after execution.

These are software-rendered captures. New physical-device/native-runtime evidence
and owner visual acceptance are not inferred from prior runs. Production signing,
physical performance and remaining release gates from PR #72 stay incomplete.

## Review dependency

Review after #72 and the existing #54–#71 chain. Retarget this PR to main only after
its approved predecessors reach main, then recheck ancestry and CI. Do not merge a
child into a parent branch that already reached main. No automatic merge.
