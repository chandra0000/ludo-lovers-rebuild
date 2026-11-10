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
- The rebuild's board geometry and fixed canvas overlay coordinates still require pixel-level calibration against the approved artwork.
- The artwork file currently present is named `ludo_board_glass.webp`, not `ludo_board_glassy.webp`. Do not rename or substitute it without confirming that the requested name refers to the same approved image.
- A GitHub CI pass proves only the checks in that workflow. It does not prove physical-device rendering or rule correctness for untested variants.

## Release gate

A change is complete only when the relevant tests pass on the committed `main` revision, the CI run is green, and documentation distinguishes automated evidence from visual/device verification. Board geometry and rule-profile acceptance remain separate gates.
