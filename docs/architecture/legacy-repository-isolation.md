# Legacy repository isolation and migration guardrails

Last reviewed: 2026-11-10

## Purpose

The older `chandra0000/ludo-lovers` repository is a historical engineering reference. It is not a runtime dependency, package dependency, asset source at build time, or second place to implement current features. The rebuild is the only active product codebase.

The older repository contains useful rule-engine work and regression history, but it also contains historical implementations, compatibility layers, provisional geometry, and multiple generations of UI. Copying folders or classes wholesale would reintroduce competing sources of truth.

## Source-of-truth rules

| Concern | Rebuild authority | Legacy repository policy |
|---|---|---|
| Flutter app and navigation | `apps/mobile/lib/src/app.dart` and `features/` | Reference only |
| Game state and transitions | `apps/mobile/lib/src/game/domain/ludo_game.dart` | Read for edge cases; do not import/copy engine classes wholesale |
| Physical board coordinates | `apps/mobile/lib/src/game/domain/board_geometry.dart` | Compare against documented route decisions; never merge coordinate tables blindly |
| Runtime board artwork | `apps/mobile/assets/images/board/ludo_board_glass.webp` | Do not load from the old repository at runtime |
| Runtime brand icon | `apps/mobile/assets/images/branding/ludo_lovers_icon.webp` | Keep one app-local canonical copy |
| Presentation and animation | `apps/mobile/lib/src/game/presentation/` and `features/match/` | Port behavior only after separating it from legacy UI/controller assumptions |
| Tests | `apps/mobile/test/` | Port scenarios and expected invariants, not stale widget labels or obsolete fixtures |

## Legacy findings to account for

The old repository's engine-consolidation record documents why a previous overlapping engine was removed and why a single path-based engine, immutable snapshots, typed transitions, stale-command rejection, deterministic replay, and board-readiness gates were introduced. Those are valuable regression requirements, not permission to transplant the old implementation into this rebuild.

The old repository also records that some route/safe-cell data was provisional and that older tests used synthetic routes. A test passing against a synthetic route does not prove the current 15×15 board geometry is correct.

## Conflict-prevention rules

1. **One engine only.** Do not add a second `LudoGame`, `LudoEngine`, route resolver, turn manager, or parallel rule implementation. Extend the rebuild's canonical domain model or explicitly replace it in a separately reviewed migration.
2. **One board coordinate map only.** All pawns, hit targets, highlights, and movement animations must use the same `BoardGeometry` mapping. Do not hard-code a second route in widgets.
3. **Rules stay out of widgets.** Presentation may request roll/move actions and animate accepted results; it must not independently decide capture, safe-cell, bonus-turn, or win rules.
4. **Immutable state at boundaries.** Copy/freeze collections exposed by game state. Rejected actions must not partially mutate the current state.
5. **Guard stale/double actions.** Disable controls during transitions and ensure callbacks cannot apply a second action against an obsolete state.
6. **Animation is not authority.** Animate from the prior state to the engine's accepted next state. Animation completion must not create or change game rules.
7. **No silent rule changes.** Keep uncertain Ludo variants explicitly provisional and covered by named tests until approved.
8. **No stale visual assumptions.** The board artwork is a full-screen composition. Preserve the entire image and its aspect ratio; calibrate logical board coordinates within the board region, not against a cropped image.
9. **No duplicate runtime assets.** Runtime assets live under `apps/mobile/assets` and are declared in `apps/mobile/pubspec.yaml`. Do not maintain a second root-level copy of the same artwork.
10. **No cross-repository imports.** The rebuild must build and test from a clean checkout without access to the legacy repository, local machine paths, or untracked files.

## Safe migration procedure

For each feature considered from the legacy repository:

1. Identify the exact behavior and its source tests/documentation.
2. Classify it as a rule, domain invariant, UI behavior, visual asset, or historical note.
3. Check whether the rebuild already implements the behavior.
4. Translate the behavior into the rebuild's existing architecture; do not copy a whole legacy module.
5. Add a focused regression test in the rebuild before changing production behavior.
6. Run formatter, analyzer, full Flutter tests, and Android debug build.
7. Update `docs/PROJECT_STATUS.md` and the relevant architecture/rules document with verified evidence.
8. Commit directly to `main`, as requested. Never force-push or overwrite a newer main revision.

## Current known risks (not silently marked fixed)

- The rebuild's compact `LudoGame` model is not yet equivalent to the legacy engine's typed command/event and versioned transition contract. Add protections incrementally; do not claim parity.
- The rebuild's board grid bounds and yard sockets have a first-pass calibration against the canonical full-screen `ludo_board_glass.webp`. Shared-track cell centres, route orientation, safe-cell identity, lane entry, and pawn-on-cell visual alignment still require dedicated visual QA before approval.
- The artwork file currently present is named `ludo_board_glass.webp`, not `ludo_board_glassy.webp`. Do not rename or substitute it without confirming that the requested name refers to the same approved image.
- A GitHub CI pass proves only the checks in that workflow. It does not prove physical-device rendering or rule correctness for untested variants.

## Release gate

A change is complete only when the relevant tests pass on the committed `main` revision, the CI run is green, and documentation distinguishes automated evidence from visual/device verification. Board geometry and rule-profile acceptance remain separate gates.


## Legacy documentation reconciliation — 2026-11-10

The old repository was reviewed beyond its README. The following documents contain durable decisions that must be carried into the rebuild; their historical implementation status and CI links are not current rebuild evidence:

- `docs/product/approved-visual-reference-baseline.md`: fixed logo, exact brand palette, premium dark/gold visual language, and a strict warning that a composite screen reference is not a cell-coordinate specification.
- `docs/board-route-acceptance.md` and `docs/architecture/step-11-board-route-and-safe-cell-approval-gate.md`: 15×15 logical grid; 52 physical shared cells; Orange/Green/Magenta/Blue entry indexes 0/13/26/39; five private lane cells plus a separate centre finish; safe-cell IDs {0, 8, 13, 21, 26, 34, 39, 47} remain owner-recorded but still require visual confirmation; the four candidate diagonal links are 4→5, 17→18, 30→31 and 43→44.
- `docs/architecture/step-09b-route-orientation-reconciliation.md`: route IDs, seat-relative progress, physical cells, safe-cell metadata and presentation mapping must remain distinct. A structurally valid route is not automatically visually approved.
- `docs/architecture/step-07-canonical-engine-consolidation-decision.md`: one pure canonical engine; immutable state; typed commands/events and errors; one state-version increment per accepted command; stale/duplicate action rejection; deterministic replay; rendering/animation never decides rules.
- `docs/game-rules/ludo-game-rules.md`: named/versioned rule profile; six-to-enter; bonus roll on six/capture/finish; third consecutive six ends turn without moving; exact finish; safe cells; explicit own/opponent stack semantics; deterministic event sequence; mode-specific match completion. These defaults were explicitly provisional pending product acceptance.
- `docs/quality/four-phase-gameplay-verification.md`: four independent gates—asset/render stability, board geometry, engine rules, and integration/stress/device testing. A green CI run is not visual or device acceptance.
- `docs/team-up-mode-acceptance.md`: a substantial local 2-vs-2 ruleset exists in the legacy project, but Team Up is outside the rebuild's agreed first milestone and must not be copied in by implication.

### Rebuild gap assessment

| Legacy requirement | Rebuild position after review |
|---|---|
| One canonical engine and immutable player snapshots | Present in the compact `LudoGame`; it is not yet equivalent to the legacy typed command/transition contract |
| Typed commands, typed events/errors, state versions, stale/duplicate rejection, deterministic replay | Not implemented in the rebuild |
| 52 physical track cells; player-relative progress 0–50; five home-lane cells 51–55; separate finish 56 | Present in the current model/geometry; the physical coordinate map is still provisional |
| Recorded safe IDs and four diagonal connector candidates | Present as provisional constants/tests; not visually approved |
| Six-to-enter, bonus on six and capture, exact finish, capture on unsafe cells | Present in the current compact engine |
| Bonus on finish and third-consecutive-six penalty | Not implemented in the current rebuild engine |
| Explicit versioned configurable rules profile and mode isolation | Not implemented; rules are currently hard-coded in `LudoGame` |
| Complete capture/stack policy including own/opponent stacks | Only basic unsafe-cell opponent capture is implemented; blockade/stack variants are not accepted |
| Five-cell lane plus distinct centre finish | Present in current progress mapping |
| Four-phase asset/geometry/engine/integration acceptance | Adopt as the rebuild's milestone gate; device and full-match evidence remain outstanding |
| Team Up mode | Intentionally deferred; do not port until the four-player Classic milestone is accepted |

### Artwork-based geometry calibration note

The rebuild now uses `ludo_board_glass.webp` as the available canonical visual source. The 15×15 grid rectangle is mapped into the fixed 576×1024 design canvas from the artwork's board bounds; yard socket centres use one shared offset pattern measured from the four circular sockets and applied symmetrically to all seats. The full-screen image is sufficient for this first-pass overlay calibration, but it does not by itself prove every route cell, start square, safe square, connector, or lane transition. Those route details remain provisional until the pawn overlay is checked in rendered screenshots. Tests must verify the single coordinate map and its invariants; they must not be described as owner visual approval.

### Migration order

1. Keep the gameplay-readiness gate closed while the first-pass artwork overlay is validated.
2. Capture rendered board screenshots with pawns placed at yard, entry, track, safe-cell, lane and finish positions.
3. Reconcile all four seat paths, corner connectors, start cells, home lanes and safe cells in one canonical definition against the screenshot evidence.
4. Upgrade the compact engine incrementally: immutable transition result, typed commands/events/errors, expected-version guard, one version increment per accepted command, then deterministic replay tests.
5. Add a named/versioned rules profile and explicitly decide the missing Classic rules before implementation.
6. Complete the four verification phases and record device evidence separately from CI.
7. Only after Classic local acceptance, consider porting Team Up and later online architecture.

Do not copy the old repository's code wholesale. Its documentation is a source of requirements and regression scenarios; its historical code and old workflow results are not proof of rebuild correctness.
