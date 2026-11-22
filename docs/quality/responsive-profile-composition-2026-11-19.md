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
- RoyalBackdrop retains its verified full-screen royal purple/midnight gradients,
  gold lighting, filigree and bokeh. It remains static, cached, pointer-excluded
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


## Android rendering isolation

The matched run44516771622 passed the known mobile baseline22bb509 but repeatedly
lost QEMU with the revised presentation. Its first current-side attempt failed
Kotlin POM resolution before runtime; the exact URLs recovered with HTTP200, and
the targeted runtime retry again lost the emulator. This narrows the issue to
changed presentation under that setup; it is not a general-environment pass.
The optional complex closed-path background lattice is removed as the first
isolated rendering candidate. Requested profile/logo/icon layout and royal
lighting remain; the approved board/engine remain unchanged. New runtime outcome
must be recorded before claiming this resolves the loss. No test is disabled.


Removing the lattice alone did not resolve QEMU loss: checkpoint44520076712
completed the first scenario, then lost the VM/emulator during local-mode checks.
The next conservative candidate restores the exact verified RoyalBackdrop painter
and the prior bounded avatar/logo decode widths128/216, while preserving larger
on-screen avatar/profile dimensions, centered logo and20dp social glyphs. The
source portraits are only145–168px; requesting240px decodes provided no new source
detail. No artwork is modified. This isolates additional painting/decode changes;
Android runtime resolution remains unverified until the next checkpoint passes.
