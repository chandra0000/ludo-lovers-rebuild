# Project status

Last updated: 2026-11-10

## Repository

- Repository: [chandra0000/ludo-lovers-rebuild](https://github.com/chandra0000/ludo-lovers-rebuild)
- Folder-structure PR #2 is merged.
- Flutter foundation PR #3 is merged into `main`.
- Routine implementation changes are now committed directly to `main`, as requested.

## Implemented foundation

- Flutter app entry point, dark premium theme, and branded home screen using the canonical Ludo Lovers icon.
- Four-player local match screen and deterministic local game engine.
- 52-cell shared-track geometry, home lanes, safe cells, capture, exact-finish checks, and win detection.
- Programmatically painted glossy glass-finish cone pawns.
- Gold vector dice with animated rotation, scale and bounce reveal; the game engine supplies the final roll.
- Pawn movement interpolates through each intermediate board cell, including release from the yard.
- Dice input is guarded at both the rendered control and roll handler while pawn movement is in progress; a widget regression verifies a second roll cannot be consumed mid-animation.
- Pawn input is disabled during the dice reveal; turns with no legal move pass after the reveal completes.
- Current-player halo and legal-move highlighting.
- Compact 2×2 arrangement for pawns sharing a cell.
- One unambiguous stack hit target; when multiple legal pawns from the active player share a cell, a chooser lets the player select the intended pawn.
- Canonical board and launcher artwork registered in the Flutter asset manifest.
- Domain, geometry, asset-integrity, home/match, deterministic turn-flow, and shared-cell selection tests.
- Flutter CI workflow for analysis, tests, Android scaffold generation, and debug APK build.

## Verified artwork facts

- Board artwork: `apps/mobile/assets/images/board/ludo_board_glass.webp`; WebP, 810×1440, 9:16, approximately 254 KB.
- The board-named file is a full-screen portrait game composition, not a board-only texture. It includes player portraits/names, the Ludo board, decorative die, turn display, and bottom controls.
- Launcher artwork: `apps/mobile/assets/images/branding/ludo_lovers_icon.webp`.
- The source assets are preserved unchanged. The app uses the canonical Flutter copies.
- Preserve the full composition and aspect ratio; place interactive overlays intentionally and calibrate pawn coordinates only against the board region inside the full-screen image.

## Validation state

- Verified CI run `42753848250` on commit `f8420520190b5f5a0830540236bbfa6c34359e92` passed formatting, static analysis, all 27 unit/widget tests, Android project generation, debug APK build, and artifact upload. The subsequent responsive-layout and release-size changes are awaiting their own CI run.
- No real Android device test has been performed/recorded.
- Board geometry remains provisional and has not been accepted through pixel-level visual calibration.
- The icon is registered as a Flutter asset and shown on the home screen; Android launcher icon generation/configuration remains outstanding.

## Known gaps

- The match screen still uses fixed design-canvas coordinates and needs responsive visual QA on real device aspect ratios.
- Pawn positions and multi-pawn stack spacing need visual calibration against the board region.
- Dice and step-by-step pawn animations are implemented; animation timing and positioning still need real-device visual QA.
- Player portraits/names and decorative UI elements baked into the full-screen artwork are static; dynamic player labels/status and controls must be layered intentionally.
- The game rule profile needs user acceptance (see [game rules](game/game-rules.md)).
- Real Android device testing and APK installation smoke test remain open.

## Next implementation sequence

1. Verify responsive canvas behavior across common portrait sizes and a constrained landscape viewport.
2. Measure debug and per-ABI release APK sizes; keep debug and release artifacts separate.
3. Calibrate the 15×15 board grid and every yard/track/home-lane coordinate from the source image.
4. Complete capture/finish feedback and tune animation timing using visual QA.
5. Make player labels, turn status, and interactions dynamic rather than relying on text baked into the static image.
6. Configure Android launcher icon generation from the canonical icon artwork.
7. Validate on a real Android device and capture visual QA evidence.

## Completion policy

Only mark a task complete when the repository change and validation evidence exist. Keep assumptions and pending visual sign-off explicit.


## Legacy repository isolation and regression prevention

- Added [legacy repository isolation and migration guardrails](architecture/legacy-repository-isolation.md). The old repository is a reference only; the rebuild remains the sole runtime source.
- The migration policy explicitly prevents parallel engines, duplicate board coordinate tables, widget-owned game rules, mutable/stale actions, and duplicated runtime assets.
- Legacy tests and rule decisions are treated as scenarios to translate into focused rebuild tests, not as proof that the rebuild already has equivalent behavior.
- The rebuild currently has not yet reached parity with the legacy engine's typed command/event and versioned transition protections. This is tracked as a risk, not represented as completed work.
- The runtime board asset remains `apps/mobile/assets/images/board/ludo_board_glass.webp`. The distinct requested spelling `ludo_board_glassy.webp` is not present in either repository tree and has not been substituted or renamed without confirmation.
- Removed redundant root-level copies of the board and brand WebP assets; the app-local asset paths are the sole runtime copies.
- Added a regression test for the dice-during-movement race found during the legacy-risk review.
