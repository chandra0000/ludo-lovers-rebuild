# Project status

Last updated: 2026-11-10

## Repository

- Repository: [chandra0000/ludo-lovers-rebuild](https://github.com/chandra0000/ludo-lovers-rebuild)
- Folder-structure PR #2 is merged.
- Flutter foundation PR #3 is merged into `main`.
- Follow-up implementation branch: `feat/app-polish-and-interaction`.
- The follow-up branch is intended for PR #4; do not treat it as merged until that PR is accepted.

## Implemented foundation

- Flutter app entry point, dark premium theme, and branded home screen using the canonical Ludo Lovers icon.
- Four-player local match screen and deterministic local game engine.
- 52-cell shared-track geometry, home lanes, safe cells, capture, exact-finish checks, and win detection.
- Programmatically painted glossy glass-finish cone pawns.
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

- A CI run on the follow-up source branch completed Dart formatting, static analysis, unit/widget tests, and Android project generation successfully; the debug APK build was still running at the time this status was updated.
- The follow-up branch has its own CI run pending; use that run as the authoritative validation for PR #4.
- No real Android device test has been performed/recorded.
- Board geometry remains provisional and has not been accepted through pixel-level visual calibration.
- The icon is registered as a Flutter asset and shown on the home screen; Android launcher icon generation/configuration remains outstanding.

## Known gaps

- The match screen still uses fixed design-canvas coordinates and needs responsive visual QA on real device aspect ratios.
- Pawn positions and multi-pawn stack spacing need visual calibration against the board region.
- Dice is currently represented by a simple numeric circular overlay; a polished vector dice component and roll animation are still required.
- Pawn movement updates engine state but does not yet animate step-by-step through intermediate cells.
- Player portraits/names and decorative UI elements baked into the full-screen artwork are static; dynamic player labels/status and controls must be layered intentionally.
- The game rule profile needs user acceptance (see [game rules](game/game-rules.md)).
- Real Android device testing and APK installation smoke test remain open.

## Next implementation sequence

1. Confirm PR #4 CI is green and obtain a debug APK artifact.
2. Implement responsive portrait layout while preserving the complete supplied composition.
3. Calibrate the 15×15 board grid and every yard/track/home-lane coordinate from the source image.
4. Add animated dice and step-by-step pawn movement with deterministic animation tests.
5. Make player labels, turn status, and interactions dynamic rather than relying on text baked into the static image.
6. Configure Android launcher icon generation from the canonical icon artwork.
7. Validate on a real Android device and capture visual QA evidence.

## Completion policy

Only mark a task complete when the repository change and validation evidence exist. Keep assumptions and pending visual sign-off explicit.
