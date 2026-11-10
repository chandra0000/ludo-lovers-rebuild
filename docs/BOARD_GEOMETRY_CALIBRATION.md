# Board geometry calibration — Phase 2

Last updated: 2026-11-10

## Goal

Calibrate every interactive pawn position against the canonical full-screen artwork without editing, cropping, stretching, or replacing the artwork:

`apps/mobile/assets/images/board/ludo_board_glass.webp`

The source is an 810×1440 portrait WebP (9:16). The Flutter design canvas is 576×1024 (the same 9:16 ratio), so the artwork is rendered as one uniformly scaled composition.

## Current implementation

- One centralized `BoardGeometry` maps normalized 15×15 board coordinates into the design canvas.
- The playfield uses a square transform: `boardHeight == boardWidth`. A logical cell has the same horizontal and vertical scale; the route is not intentionally distorted to fill a rectangular region.
- The four yard quadrants share one four-socket offset pattern: x offsets 1.8/3.8 and y offsets 1.8/3.8 grid units. The pattern is mirrored by the seat's yard origin.
- The 52-cell shared route, per-seat entry indexes (Orange 0, Green 13, Magenta 26, Blue 39), five-cell private lanes, separate centre finish, and safe-cell metadata remain centralized in `BoardGeometry`.
- Tests cover route uniqueness and bounds, per-seat route traversal, lane separation, finish mapping, safe-cell index bounds, square grid scaling, and all 16 starting pawn positions.
- The 393×873 match-canvas capture test runs rasterization outside the widget test's fake-async zone, then writes `test-artifacts/match-canvas-393x873.png` for CI upload.

## Calibration values — provisional, not visually approved

All values below are implementation estimates pending comparison with the CI-rendered canvas and direct pixel measurement of the original source artwork. They must not be represented as pixel-verified:

| Parameter | Current value | Status |
|---|---:|---|
| Design canvas | 576×1024 | Exact 9:16 canvas contract |
| Logical grid | 15×15 | Product geometry contract |
| Board left | 17.78 | Provisional |
| Board top | 199.1 | Provisional source-art alignment estimate |
| Board width | 540.44 | Provisional |
| Board height | 540.44 (tied to width) | Square-grid constraint implemented |
| Yard socket x offsets | 1.8, 3.8 grid units | Provisional |
| Yard socket y offsets | 1.8, 3.8 grid units | Provisional |
| Shared route | 52 unique cells | Structural tests pass; artwork alignment pending |
| Safe indexes | 0, 8, 13, 21, 26, 34, 39, 47 | Legacy candidate set; visual approval pending |

The square-grid constraint is a correctness improvement: the 15×15 route must not be stretched into unequal-width and unequal-height cells. It does not by itself prove the rectangle is correctly aligned to the artwork.

## Required visual measurement and acceptance

1. Open the CI artifact `ludo-lovers-match-canvas-393x873` from a successful run and compare it with the original 810×1440 artwork.
2. Determine the exact artwork-to-canvas scale and offsets. Confirm that the full composition remains visible and that no crop or stretch has been introduced.
3. Measure the outer playfield grid boundary from source pixels, then calculate its 15×15 cell pitch. Record pixel coordinates and normalized canvas coordinates.
4. Measure all 16 circular yard socket centres independently from the source image. Do not assume quadrant symmetry until the measurements confirm it.
5. Measure representative route anchors: all four entries, every straight segment, each diagonal/corner transition, all safe cells, each five-cell home lane, and the centre finish.
6. Compare rendered pawn centres with the measured source anchors. Record maximum pixel error and require no more than 2 logical-canvas pixels at the 576×1024 design size for fixed anchor points.
7. Update only the centralized `BoardGeometry` constants and retain numeric regression tests for the measured anchors.
8. Review at 360×800, 393×873, 412×915 and 800×360. Confirm portrait artwork stays 9:16 and is letterboxed rather than cropped in landscape.
9. Keep `visualApprovalPending = true` until the rendered artifact has been inspected and the measured anchor tests pass. CI green alone is not visual sign-off.

## Current blockers / boundaries

- The latest pipeline failure was caused by the screenshot test waiting indefinitely during `RenderRepaintBoundary.toImage`; static analysis had already passed. The capture now uses `tester.runAsync` for the raster operation. A fresh successful run is required to validate this fix.
- The previous failed run did not produce a screenshot artifact. Do not use that run as visual evidence.
- Safe-cell identity, route orientation, connector placement, home-lane alignment, stack placement, and real-device rendering remain unapproved until pixel comparison and device QA are complete.
- Do not redraw or modify the canonical artwork as a shortcut to make overlay coordinates appear correct.

## Phase 2 completion gate

Phase 2 is complete only when:
- CI analysis and all widget tests pass;
- the screenshot artifact exists and can be downloaded;
- source-pixel measurements are recorded for the grid bounds and 16 yard sockets;
- all route/lane/finish anchor tests use measured coordinates;
- the rendered comparison meets the stated tolerance; and
- visual approval is explicitly recorded.

Until then this work is **Phase 2 implementation in progress**, not final visual calibration.
