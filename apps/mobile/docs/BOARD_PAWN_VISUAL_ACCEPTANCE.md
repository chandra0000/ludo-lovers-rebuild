# Board & Pawn Visual Acceptance

Status: **pending human visual approval**  
Canonical artwork: `assets/images/board/ludo_board_glass.webp`  
Design canvas: **576 × 1024 logical units** (9:16)  
Source artwork: **810 × 1440 pixels** (9:16)

This milestone validates the existing geometry and rendering against the approved
artwork. It must not modify, crop, recolour, stretch, or replace the board artwork,
logo, palette, or branding.

## Existing implementation to reuse

- `BoardGeometry` is the single source of truth for 52 track anchors, 20 home
  lane anchors, 16 yard sockets, safe-cell metadata and the finish anchor.
- `BoardPreviewScreen` is the existing read-only anchor overlay. Extend it if
  needed; do not create a competing calibration screen.
- `board_geometry_acceptance_test.dart` checks route topology and key artwork
  anchors.
- `board_geometry_pixel_anchor_test.dart` pins all 52 route and 20 lane centres.
- `board_pawn_placement_test.dart` checks live pawn centre placement at
  393 × 873 logical pixels.
- `match_screen.dart` currently exposes 44 × 48 logical-pixel pawn hit regions
  and a chooser when multiple friendly pawns on one cell can move.

## Important fixture constraint

A Ludo match has only 16 pawns. It is mathematically impossible for one valid
match state to show all 16 yard pawns **and** additional track stacks, a home
corridor pawn, and a finished pawn simultaneously. Use the deterministic,
test-only states in `test/fixtures/board_acceptance_presets.dart` as separate
inspection presets:

| Preset | Required visual state |
|---|---|
| `allYardSocketsFilled` | All 16 yard sockets occupied |
| `singlePawnOnTrack` | One pawn at progress 5 |
| `friendlyTwoPawnStackAtCell10` | Two friendly pawns at physical track cell 10 |
| `mixedThreePawnStackAtSafeCell21` | Three colours stacked on safe cell 21 |
| `pawnAtHomeLaneEntry` | Orange pawn at progress 51, first home-lane cell |
| `pawnAtGoal` | Orange pawn at progress 56, finish anchor |

These are test fixtures, not production routes and not player-accessible modes.

## Pass A — geometry and artwork anchors

- [ ] Confirm the displayed asset is the canonical WebP, with no fallback or
  stale asset path.
- [ ] Compare all 16 yard socket centres with the centre of their white pocket
  rings. Check the pawn base/pedestal and shadow, not just the pawn tip.
- [ ] Compare all 52 shared-track centres, including safe cells
  **0, 8, 13, 21, 26, 34, 39, 47**.
- [ ] Inspect all four connector edges **4, 17, 30, 43** for corner clipping.
  (These are the route's diagonal connector transitions.)
- [ ] Check all 20 home-lane anchors and the finish hub. Progress 51–55 maps to
  the five lane cells; progress 56 maps to the finish anchor.
- [ ] Convert screenshot coordinates back to the 576 × 1024 design canvas using
  the actual fitted image scale and letterbox offset. Do not measure a resized
  chat preview.
- [ ] Acceptance: overlay centre error no greater than **1 logical pixel** at
  the design canvas scale, unless a documented artwork measurement uncertainty
  is agreed before changing an anchor.

## Pass B — pawn footprint, stacks and touch behaviour

Run at minimum at 360 × 640, 393 × 873 and 412 × 915 logical-pixel viewports.
Repeat at the device's actual device-pixel ratio.

- [ ] Single pawn: centred on the anchor; base shadow/pedestal does not drift.
- [ ] Two friendly pawns: both rims remain visually identifiable; tapping the
  shared cell exposes the existing pawn chooser when both are legal.
- [ ] Three-pawn mixed stack: all three colours remain distinguishable; moving
  pawn paints above resting pawns during animation.
- [ ] Yard: all 16 pawn bases remain inside their pocket rings and do not touch
  adjacent ring borders.
- [ ] Every interactive pawn target is at least **44 × 44 logical pixels**.
  Verify actual hit-test rectangles, not only the visible cone dimensions.
- [ ] Taps near neighbouring cells select only the intended cell/pawn. Check
  edge and corner targets, including the four diagonal connector transitions.
- [ ] Invalid yard selection with a non-six roll gives feedback without
  accidentally selecting a neighbouring pawn; a six releases the pawn.

Do not adopt fixed scale/offset values (for example 0.80× or 0.65×) until
screenshots demonstrate they fit the actual artwork and touch regions. Visual
footprint and hit target are separate contracts.

## Pass C — screenshot and visual regression harness

- [ ] Capture the existing `board_preview_capture` anchor overlay.
- [ ] Capture each deterministic preset at all three viewports.
- [ ] Save approved references only after human review of the canonical asset.
- [ ] Add/retain widget golden tests with fixed viewport and device-pixel ratio.
- [ ] Upload screenshots as CI artifacts for inspection; artifact generation is
  not equivalent to visual approval.

## CI golden policy

CI must compare against committed golden files and must never rewrite them.
Run normal tests with:

```sh
cd apps/mobile
flutter test --reporter expanded
```

Only when an intentional visual change is approved, update references locally from PowerShell:

```powershell
cd apps/mobile
.\\tool\\update_goldens.ps1
git diff -- test
```

Or run the equivalent Flutter command directly: `flutter test --update-goldens --reporter expanded`.

Review every changed PNG before committing. Never add `--update-goldens` to
the normal CI test command.

## Release-build device acceptance

- [ ] Download the release APK artifact from the successful GitHub Actions run.
- [ ] Install on a physical Android device and verify first launch, board asset
  loading, 16-yard layout, dice interaction, pawn selection, movement and
  turn handoff.
- [ ] Record device model, Android version, display resolution, logical size,
  device-pixel ratio and APK ABI.
- [ ] Capture screenshots for the six presets (where available through the
  test harness) and attach them to the milestone review.
- [ ] Keep `BoardGeometry.visualApprovalPending == true` until a human signs
  off on the screenshots and physical-device review.

## Sign-off record

- Reviewer:
- Device(s):
- Viewports checked:
- Screenshot artifact/run:
- Geometry deviations:
- Hit-target deviations:
- Approved / changes required:
- Date:
