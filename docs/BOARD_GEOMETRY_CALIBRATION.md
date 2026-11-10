# Board geometry calibration — Phase 2

Last updated: 2026-11-10

## Current implementation

The canonical board artwork is a full-screen 810×1440 portrait composition. Its playable board is **not** a uniform square 15×15 grid: the horizontal arms, vertical arms and central hub have different cell proportions and small offsets. The previous single square-grid transform caused visible pawn misalignment, especially in the yard sockets.

The rendering contract has therefore been changed:

- The 52-cell logical route and all game rules remain in the domain layer.
- Rendering uses source-artwork pixel anchors for each shared-track cell, each of the 20 home-lane cells, the finish centre and all 16 yard sockets.
- BoardGeometry.normalizedPosition resolves a pawn's logical progress to its explicit source-artwork anchor.
- BoardGeometry.canvasPosition applies one uniform 810×1440 → 576×1024 transform. No crop, stretch, recolour, redraw, or replacement of the canonical artwork is performed.
- The board preview renders the same anchor table as the live match; it does not maintain a second coordinate map.

## Source-to-canvas transform

| Property | Value |
|---|---:|
| Canonical artwork | 810×1440 px |
| Design canvas | 576×1024 units |
| Aspect ratio | 9:16 |
| Uniform scale | 0.711111… |
| Logical shared route | 52 cells |
| Private lanes | 5 cells × 4 players |
| Yard sockets | 16 |

All source-pixel anchors are converted by x_canvas = x_source × 576/810 and y_canvas = y_source × 1024/1440.

## Measured arm anchors

The following centre coordinates are in source-artwork pixels. Arrays are ordered left-to-right or top-to-bottom.

| Anchor set | Source-pixel centres |
|---|---|
| Left horizontal arm X | 48, 96.5, 144.5, 192, 240, 287.5 |
| Right horizontal arm X | 520.5, 568, 616, 664, 712, 760 |
| Upper vertical arm X | 341, 404, 466.5 |
| Lower vertical arm X | 351, 403, 455 |
| Upper vertical arm Y | 326, 377.5, 427.5, 476.5, 525, 577 |
| Lower vertical arm Y | 785.5, 837.5, 888, 940, 991.5, 1045 |
| Horizontal arm Y | 625, 677, 729 |
| Finish centre | (403, 681) |

These arm anchors are applied to the logical cells in the existing sharedTrack order. The route index order, player entry indexes and safe-cell metadata are not changed by this rendering refactor.

## Yard socket centres

The 16 circular socket centres were measured independently from the canonical artwork rather than mirrored from one generic quadrant offset. Coordinates are source pixels; pawn index order is top-left, top-right, bottom-left, bottom-right.

| Player | Socket centres (x, y) |
|---|---|
| Orange | (114.2, 401.4), (215, 402.6), (115.4, 495), (215, 497.4) |
| Green | (593, 402.6), (692.6, 402.6), (593, 496.2), (692.6, 497.4) |
| Blue | (117.8, 872.2), (217.4, 873.4), (117.8, 968.2), (217.4, 968.2) |
| Magenta | (594.2, 874.6), (691.4, 873.4), (593, 967), (692.6, 967) |

## Automated verification

- Geometry tests preserve the 52 unique logical route cells, player-relative route traversal, five-cell lanes, four connector transitions and existing safe-cell IDs.
- Numeric tests pin all 16 yard sockets, representative route anchors, finish position and the source-to-canvas transform.
- Widget tests verify that the match screen and board preview consume the centralized geometry map.
- CI captures the board preview at 393×873 and uploads both that preview and the canonical source artwork as separate artifacts for repeatable inspection.
- CI also runs the deterministic match screenshot, unit/widget suite, Android emulator integration smoke test, and debug/profile/release APK builds.

## Expanded coordinate regression coverage — 2026-11-10

- Added a complete pixel-anchor fixture for all 52 shared-track positions, rather than checking only representative route cells.
- Added exact source-pixel fixtures for all 20 home-lane positions and checks that route/lane centres do not overlap.
- Added a live MatchScreen placement test that compares pawn widget centres with the centralized transform on a 393×873 viewport for a shared-track cell, a private-lane cell, and the finish centre.
- Existing yard placement coverage checks all 16 starting sockets in the live widget tree; the asset test verifies the bundled canonical image remains 810×1440.
- These checks protect the current coordinate contract against accidental drift. They do not independently prove that the measured anchors match the intended artwork pixels; human inspection and physical-device approval are still mandatory.

## Visual acceptance still pending

The updated source anchors have been overlaid on the canonical source image. The diagnostic overlay shows the route markers centred in their cells and the yard crosshairs aligned with the circular wells. This is useful visual evidence, but it is not final owner approval or physical-device validation.

Keep BoardGeometry.visualApprovalPending = true until:
1. The latest successful CI artifact is inspected at full resolution.
2. The owner confirms that pawn centres align with the intended artwork cells and sockets.
3. The same placement is checked on a physical Android device at normal display scaling.
4. Any measured residual offsets are corrected and covered by numeric regression tests.

Do not replace the artwork, introduce a second geometry table, or alter the logical route/rules to compensate for a rendering-coordinate issue.
