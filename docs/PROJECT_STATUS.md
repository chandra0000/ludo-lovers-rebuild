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

## Board calibration implementation — 2026-11-10

- Replaced the single uniform 15×15 rendering transform with explicit source-artwork anchors for the 52 shared-track positions, 20 home-lane positions, centre finish and 16 yard sockets. The logical route order and game rules remain unchanged.
- The artwork's horizontal arms, vertical arms and centre hub have different proportions; the renderer now maps those regions independently while preserving one 9:16 source-to-canvas scale.
- Yard socket centres were measured independently from the original 810×1440 WebP. The board preview and live match now use the same centralized anchor functions.
- Added numeric tests for all 16 yard socket coordinates, representative shared-route anchors, finish position and full-artwork canvas mapping.
- CI now uploads the canonical source artwork alongside the 393×873 board preview and match screenshot. The Android emulator smoke-test step is bounded to 15 minutes to prevent a stalled emulator from consuming the full job timeout.
- The source-pixel overlay has been inspected and markers appear centred in their cells/wells. Final visual approval and physical Android validation remain pending; BoardGeometry.visualApprovalPending stays true.
- Latest implementation commits are on main. The latest CI run must pass before this calibration implementation is considered validated.

## Validation state

- Latest fully verified baseline run [42793354362](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42793354362) passed all analysis, test, emulator and APK build stages on commit `643e6dfa6b990c513252c7488d60e42dd6603285`. Newer source-anchor calibration commits require their own green CI run.

- Verified CI run [42754693581](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42754693581) on commit `a8c80bbc1b4799630b14e49230baddf52ae99fb8` passed formatting, static analysis, all 27 unit/widget tests, Android project generation, debug APK build, split release APK builds, and both artifact uploads.
- Measured package outputs on that verified baseline: debug APK 144 MB; split release APKs 13.4 MB (armeabi-v7a), 16.2 MB (arm64-v8a), and 17.5 MB (x86_64). The arm64 release APK is the likely Android-phone target; use release rather than the large debug APK for device installation/performance checks.
- Downloadable CI artifacts: [debug APK](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42754693581/artifacts/13734718462) and [split release APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42754693581/artifacts/13734504994).
- Latest verified CI run [42758341034](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42758341034) passed formatting, static analysis, unit/widget tests, Android project generation, debug APK build, split release APK builds, and artifact uploads on commit `c6742c444f392a2cd5e60f43448eba66a007eb71`. Later geometry-centralization and expanded regression-test commits are newer than that run; their CI must pass before they are considered validated.
- No real Android device test or pixel-calibration sign-off has been performed. A deterministic 393×873 viewport widget screenshot is now captured from the actual match canvas and uploaded as a CI artifact; it is diagnostic evidence, not proof that the provisional coordinates align with the artwork.
- The geometry-invariant and regression-test changes initially exposed six `prefer_const_constructors` analyzer infos under the repository's `--fatal-infos` CI policy. These were fixed in commit `7c485e50cd54e7db23aa7aab29dc34d754ba8182`; CI run [42760362218](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42760362218) is the validation run for that fix and must finish green before the code is considered validated.
- Board geometry remains provisional. Phase 2 now enforces a square 15×15 playfield transform and a consistent four-socket yard pattern across all four quadrants. Automated tests cover all 52 unique shared-track cells, each seat's 51-cell route, five home-lane positions, separate finish, safe-cell metadata, four candidate diagonal connectors, and all 16 starting-yard pawn overlay positions. These are structural and coordinate-contract checks, not pixel-level proof that the route or safe cells match the artwork.
- The icon is registered as a Flutter asset and shown on the home screen; Android launcher icon generation/configuration remains outstanding.


## Phase 3 — engine correctness implementation

- Added immutable named rule profiles: `ludo-lovers-current@1` remains the default compatibility behaviour; `classic@1` is opt-in and implements the proposed finish bonus and third-consecutive-six penalty. Classic remains pending product acceptance and is not silently enabled.
- Added immutable game state versions. Accepted roll, move, and pass transitions increment the version once; callers can provide an expected version to reject stale actions and a unique command ID to reject duplicate submissions.
- Added deterministic typed transition events for dice rolls, pawn movement, captures, turn changes, third-six penalties, and wins. Events carry an ordered sequence and resulting state version.
- Added regression tests for the opt-in Classic rules, version increments, stale/duplicate rejection, deterministic capture event ordering, and compatibility-profile behaviour.
- These changes are committed to `main`. CI run [42764125360](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42764125360) passed formatting, strict analysis, all unit/widget tests, deterministic screenshot upload, Android project generation, debug APK build, split release APK builds, and artifact uploads on commit `e86b3cd8cd081cfcbb30fd8fa789de1f06f68d3d`. This validates the implemented Phase 3 scope, not durable replay or complete legacy-engine parity.


## Phase 4 — integration, stress, and device QA implementation

- Added a deterministic stress test that runs up to 2,500 accepted engine transitions and checks four-player snapshots, pawn-progress bounds, exactly one state-version increment per command, unique in-memory command IDs, and contiguous event sequencing/version stamps.
- Added tests proving player lists, pawn-progress lists, event lists, and command-ID sets exposed by a game snapshot cannot be mutated externally.
- Added an Android integration smoke test that launches the app and repeats home → local match → home navigation three times, verifying the board artwork, dice control, and all four player pawns.
- Added an API 35 x86_64 Android emulator job to CI to run that integration test.
- CI formatting now includes `integration_test/`; documentation records the automated and manual acceptance gates.
- These changes are committed directly to `main`. The latest CI run for this Phase 4 change is pending; do not mark Phase 4 complete until emulator integration, unit/widget tests, analysis, screenshot upload, debug APK, and split release builds all pass.
- Physical Android device QA remains pending and must be recorded separately. Emulator CI does not prove touch alignment, frame pacing, battery/thermal behaviour, or final artwork alignment.

See [four-phase gameplay verification](quality/four-phase-gameplay-verification.md) for the acceptance checklist.

## Local match recovery — 2026-11-10

- Added a schema-versioned JSON snapshot codec to the immutable domain engine. Snapshots preserve all four players' pawn progress, active seat, pending dice value, winner, rule-profile settings/version, state version, consecutive-six count, and accepted command IDs.
- Added `SavedMatchStore` using the existing `shared_preferences` dependency. It stores one local match plus AI seat assignments and the deterministic AI seed; malformed or unsupported saved data is discarded rather than guessed.
- Match screens save their initial state and every accepted roll, move and automatic pass. The screen also observes app lifecycle changes and flushes the current accepted state when the app backgrounds or becomes inactive. AI dice values are derived deterministically from the configured seed and game state version, so a resumed match does not restart a hidden random-number sequence.
- The home screen offers **RESUME SAVED MATCH** when a valid local snapshot exists and provides an explicit discard action. Resume restores the same AI seats/seed and game state; this is local-device recovery, not cloud sync.
- Presentation-only animation progress and transient last-transition events are not persisted. A restored match renders from the authoritative accepted game state; an in-flight visual hop is not replayed.
- Added domain codec tests, store persistence/corruption tests, a home-to-resumed-match widget test, and coverage for a restored AI turn with a pending unplayable roll.
- These changes are committed directly to `main`. CI validation is pending for the latest commit; do not mark persistence acceptance complete until strict analysis, all Flutter tests and profile/release builds pass. Android process-kill/device validation remains outstanding.

## Known gaps

- The match screen still uses fixed design-canvas coordinates and needs responsive visual QA on real device aspect ratios.
- Pawn overlays use one centralized `BoardGeometry` contract for the 576×1024 design canvas, board-grid rectangle and yard socket offsets. Current first-pass values are board rectangle (left 17.78, top 199.1, width 540.44, height 540.44) and yard offsets (1.8/3.8 on both axes). The square transform prevents non-uniform cell distortion; all values remain explicit estimates, not pixel-verified measurements. See [Phase 2 board geometry calibration](BOARD_GEOMETRY_CALIBRATION.md). All 16 starting pawn overlays are checked against the same mapping in a widget test. Shared-track route orientation, safe-cell identity, connector placement, lane alignment, pawn stacking and real-device appearance remain provisional.
- Dice and step-by-step pawn animations are implemented; animation timing and positioning still need real-device visual QA.
- Player portraits/names and decorative UI elements baked into the full-screen artwork are static; dynamic player labels/status and controls must be layered intentionally.
- The game rule profile needs user acceptance (see [game rules](game/game-rules.md)).
- Real Android device testing and APK installation smoke test remain open.

## Next implementation sequence

1. Complete the Phase 4 CI run and inspect any emulator/test/build failures before further feature work.
2. Perform and record the physical Android device smoke test using the Phase 4 checklist.
3. Complete artwork pixel calibration and owner approval before changing the visual-approval gate.

1. Verify responsive canvas behavior across common portrait sizes and a constrained landscape viewport.
2. Measure debug and per-ABI release APK sizes; keep debug and release artifacts separate.
3. Inspect the CI artifact `ludo-lovers-match-canvas-393x873` generated by the deterministic widget screenshot test. Compare the rendered canvas with the original 810×1440 artwork, record the artwork-to-canvas transform, and measure the 15×15 grid boundary and each of the 16 yard socket centres from source pixels; do not infer them from a cropped preview. The automated capture is a widget-rendered diagnostic, not a physical-device screenshot. Compare rendered pawn centres at all 16 yards, four entries, representative straight/connector track cells, safe cells, each home lane, finish and stacked positions. Adjust only centralized `BoardGeometry` constants from measured screenshot evidence, then retain numeric anchor regression tests.
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
- The canonical full-screen artwork was inspected. The current board rectangle and yard socket offsets are retained as first-pass estimates, not as pixel-verified measurements. The visual-approval gate remains open.
- The rebuild's compact engine does not yet have the legacy typed command/event/error and versioned transition contract.
- The rebuild currently lacks the third-consecutive-six penalty, finish bonus roll, and a named/versioned rule profile.
- Team Up remains deferred from the rebuild's first milestone.
- The legacy four-phase verification plan is adopted: asset/render stability, board geometry, engine correctness, integration/stress/device QA.
- Old CI run numbers and old repository implementation status are historical only; rebuild validation must be evidenced on the current rebuild commit.


## Legacy feature recovery — plan established

- Added [Legacy Feature Recovery Plan](LEGACY_FEATURE_RECOVERY_PLAN.md), an actionable old-to-new feature inventory with target modules, priority, and acceptance criteria.
- The plan separates implemented foundations from provisional geometry/rules, missing onboarding/setup and local AI, and deliberately deferred Team Up/online multiplayer.
- Migration guardrails remain in force: one engine, one BoardGeometry source, canonical full-screen artwork unchanged, and approved glass-cone pawn design preserved.
- Immediate implementation focus is P0 board calibration/topology and opt-in Classic rules parity. P1 onboarding/setup and seeded local AI follow after the board and rule acceptance gates.
- This documentation commit does not claim that missing features have been implemented or visually/device validated. Each feature will be recorded as complete only with its own tests and CI evidence.


## P1 — local product experience implementation (2026-11-10)

- Added a three-page first-run onboarding flow after the approved splash. Skip and Get Started persist completion locally with `shared_preferences`; returning launches bypass onboarding and open Home.
- Expanded game setup with 1–4 human seats. Remaining seats are assigned to seeded local AI; the existing four-player pass-and-play path remains available. Team Up remains visibly disabled and is not represented as playable.
- Added `SeededLudoAi`: it evaluates only pawn indexes returned by the authoritative engine's legal-action API, scores resulting engine states, prioritizes captures/finishes/progress, and resolves ties deterministically. Match orchestration runs AI rolls and moves through the same engine transitions and animation path.
- Expanded board preview into a read-only geometry audit overlay showing all 52 shared-track cells, candidate connector locations, safe cells, home lanes, centre finish and all 16 provisional yard sockets. It reuses the single `BoardGeometry` map and canonical board artwork unchanged.
- Added AI strategy regression tests and widget coverage for first-launch onboarding and human-vs-AI seat assignment.
- This P1 slice is committed directly to `main`. Automated CI validation is pending; deterministic full-match coverage, visual calibration, responsive/device review, and physical Android acceptance remain open. Do not treat the preview as pixel approval or the P1 milestone as fully accepted until these gates pass.
