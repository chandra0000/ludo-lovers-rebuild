# Project status

Last updated: 2026-11-10

## Repository

- Repository: [chandra0000/ludo-lovers-rebuild](https://github.com/chandra0000/ludo-lovers-rebuild)
- Folder-structure PR #2 was merged.
- Flutter app foundation and ongoing implementation are on `feat/flutter-app-foundation`.
- PR #3 is open: [feat: establish documented Flutter app foundation](https://github.com/chandra0000/ludo-lovers-rebuild/pull/3).
- The branch is not yet merged into `main`.

## Implemented foundation

- Flutter app entry point, dark premium theme, and home screen.
- Local four-player match screen and deterministic local game engine.
- 52-cell shared-track geometry, home lanes, safe cells, capture, exact-finish checks, and win detection.
- Programmatically painted glass-finish cone pawns.
- Current-player halo and legal-move highlight.
- Compact 2×2 layout for multiple pawns sharing a cell.
- Canonical board and launcher icon files are present under `apps/mobile/assets/images`.
- Flutter asset manifest references both canonical paths.
- Unit, geometry, asset-integrity, and widget tests.
- CI workflow for analysis, tests, Android scaffold generation, and debug APK build.

## Verified artwork facts

- Board artwork: `apps/mobile/assets/images/board/ludo_board_glass.webp`; WebP, 810×1440, 9:16, approximately 254 KB.
- Launcher artwork: `apps/mobile/assets/images/branding/ludo_lovers_icon.webp`.
- The board-named file is a full-screen portrait game composition, not a board-only texture. It includes player portraits/names, the Ludo board, decorative die, turn display, and bottom controls.
- The app must preserve the source composition and aspect ratio. Dynamic gameplay elements need carefully positioned overlays; static artwork elements must not be mistaken for live controls.
- The original asset is also present in the repository's top-level upload paths. The app loads the canonical Flutter copy.

## Validation state

- Earlier CI runs failed during static analysis; the reported analyzer issues have been addressed and new CI runs are in progress.
- Do not claim tests or APK build pass until the latest workflow run completes successfully.
- No real Android device test has been performed/recorded.
- Board geometry remains provisional and has not been accepted through pixel-level visual calibration.
- The launcher icon file is registered as a Flutter asset but Android launcher icon generation/configuration is still outstanding.

## Known gaps

- The match screen still uses fixed design-canvas coordinates and needs responsive visual QA on real device aspect ratios.
- Pawn positions must be calibrated against the actual board grid and image's displayed rectangle.
- Multi-pawn stack spacing and pawn tap targets need visual/touch validation.
- Dice is currently represented by a simple numeric circular overlay; a polished vector dice and roll animation are still required.
- Pawn movement updates engine state but does not yet animate step-by-step through intermediate cells.
- Player portraits/names and decorative UI elements baked into the full-screen artwork are static; dynamic player labels/status must be layered intentionally.
- The game rule profile needs user acceptance (see [game rules](game/game-rules.md)).
- Real Android device testing and APK installation smoke test remain open.

## Next implementation sequence

1. Get the latest CI run green: format, analyze, unit/widget tests, Android scaffold generation, and debug APK build.
2. Implement the match UI as a responsive portrait composition using the canonical artwork without cropping or stretching.
3. Calibrate the 15×15 board grid and every yard/track/home-lane coordinate from the source image.
4. Add animated dice and step-by-step pawn movement with deterministic animation tests.
5. Make player labels, turn status, and interactions dynamic rather than relying on text baked into the static image.
6. Configure the Android launcher icon from the canonical icon artwork.
7. Validate on a real Android device and capture visual QA evidence.

## Completion policy

Only mark a task complete when the repository change and validation evidence exist. Keep assumptions and pending visual sign-off explicit.
