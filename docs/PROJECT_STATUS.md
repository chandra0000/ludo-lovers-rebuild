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
- Captures and reaching the finish now produce explicit in-game feedback after the pawn movement animation; capture feedback identifies the retained extra turn.
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

- Verified CI run [42754693581](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42754693581) on commit `a8c80bbc1b4799630b14e49230baddf52ae99fb8` passed formatting, static analysis, all 27 unit/widget tests, Android project generation, debug APK build, split release APK builds, and both artifact uploads.
- Measured package outputs on that verified baseline: debug APK 144 MB; split release APKs 13.4 MB (armeabi-v7a), 16.2 MB (arm64-v8a), and 17.5 MB (x86_64). The arm64 release APK is the likely Android-phone target; use release rather than the large debug APK for device installation/performance checks.
- Downloadable CI artifacts: [debug APK](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42754693581/artifacts/13734718462) and [split release APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42754693581/artifacts/13734504994).
- Latest verified CI run [42758341034](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42758341034) passed formatting, static analysis, unit/widget tests, Android project generation, debug APK build, split release APK builds, and artifact uploads on commit `c6742c444f392a2cd5e60f43448eba66a007eb71`. Later geometry-centralization and expanded regression-test commits are newer than that run; their CI must pass before they are considered validated.
- No real Android device test has been performed/recorded.
- Board geometry remains provisional. Automated tests cover all 52 unique shared-track cells, each seat's 51-cell route, five home-lane positions, separate finish, safe-cell metadata, four candidate diagonal connectors, and all 16 starting-yard pawn overlay positions. These are structural and coordinate-contract checks, not pixel-level proof that the route or safe cells match the artwork.
- The icon is registered as a Flutter asset and shown on the home screen; Android launcher icon generation/configuration remains outstanding.

## Known gaps

- The match screen still uses fixed design-canvas coordinates and needs responsive visual QA on real device aspect ratios.
- Pawn overlays use one centralized `BoardGeometry` contract for the 576×1024 design canvas, board-grid rectangle and yard socket offsets. The current board rectangle and yard offsets are first-pass estimates, not pixel-verified measurements. All 16 starting pawns are checked against the same mapping in a widget test. Shared-track route orientation, safe-cell identity, connector placement, lane alignment, pawn stacking and real-device appearance remain provisional.
- Dice and step-by-step pawn animations are implemented; animation timing and positioning still need real-device visual QA.
- Player portraits/names and decorative UI elements baked into the full-screen artwork are static; dynamic player labels/status and controls must be layered intentionally.
- The game rule profile needs user acceptance (see [game rules](game/game-rules.md)).
- Real Android device testing and APK installation smoke test remain open.

## Next implementation sequence

1. Verify responsive canvas behavior across common portrait sizes and a constrained landscape viewport.
2. Measure debug and per-ABI release APK sizes; keep debug and release artifacts separate.
3. Capture rendered screenshots with pawns at yard, all four entries, representative straight/connector track cells, safe cells, each home lane, finish and stacked positions. Compare against the unchanged 9:16 board artwork and adjust only centralized `BoardGeometry` constants from measured screenshot evidence.
4. Tune capture/finish feedback placement and animation timing using visual QA.
5. Replace the baked-in player names/status with dynamic player labels and online/offline indicators without altering the artwork.
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


## Legacy repository requirements audit — 2026-11-10

The old repository's product baseline, route acceptance, immutable board/route decisions, engine consolidation decision, rule specification, Team Up acceptance, and four-phase gameplay verification plan have been reviewed. The durable requirements and a code-vs-document gap matrix are now recorded in [legacy repository isolation and migration guardrails](architecture/legacy-repository-isolation.md).

Important corrections:
- No guessed yard/board coordinate calibration is accepted. The recent inferred coordinate edits were reverted; current geometry remains provisional.
- The rebuild's compact engine does not yet have the legacy typed command/event/error and versioned transition contract.
- The rebuild currently lacks the third-consecutive-six penalty, finish bonus roll, and a named/versioned rule profile.
- Team Up remains deferred from the rebuild's first milestone.
- The legacy four-phase verification plan is adopted: asset/render stability, board geometry, engine correctness, integration/stress/device QA.
- Old CI run numbers and old repository implementation status are historical only; rebuild validation must be evidenced on the current rebuild commit.
