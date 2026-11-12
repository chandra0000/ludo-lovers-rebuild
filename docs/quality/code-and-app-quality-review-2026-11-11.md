# Code and app quality review — 2026-11-11

## Scope and evidence

This is a source-level review of the rebuild after PRs #15 and #21 merged.
The latest completed verification for the benchmark branch was GitHub Actions
run [42945553165](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42945553165).
It passed dependency resolution, Dart formatting step, strict Flutter analysis,
unit/widget tests, benchmark generation, visual artifact checks, Android project
generation, profile APK builds and release APK builds.

That run validates the PR head that was merged. It is not a physical-device
acceptance report and does not prove the app is release-ready.

## Strengths

- One immutable domain engine owns movement, capture, safe-square, blockade,
  bonus-turn and win decisions.
- Named/versioned rule profiles keep compatibility behavior as the default
  while proposed Classic behavior remains opt-in.
- State versions, command IDs, ordered events and schema-versioned snapshots
  provide a useful foundation for safe local recovery and future sessions.
- Seeded AI asks the same engine for legal actions rather than implementing
  independent movement rules.
- Board coordinates are centralized in `BoardGeometry`; the canonical
  810×1440 board artwork is retained unchanged.
- Dice and pawn animations present accepted engine state, and reduced-motion
  handling exists.
- Automated tests cover domain rules, widget interactions, snapshot migration,
  deterministic stress behavior and benchmark workloads.

## Findings and priorities

### P0 — physical board and touch acceptance remains open

The board artwork is a full-screen composition with baked-in decoration and
controls. Pawn overlays and route anchors are centralized and regression-tested,
but the repository explicitly keeps `BoardGeometry.visualApprovalPending`
true. Automated coordinate tests do not prove that pawn centres, touch targets,
stack selection, safe cells or lane overlays align on a real phone.

Required before release:
- Compare the native-resolution match screenshot against the canonical artwork.
- Verify pawn centres and hit targets on a physical Android device.
- Test at least the documented portrait sizes and confirm the artwork is neither
  cropped nor distorted.
- Capture real-device gameplay recordings for movement, capture, blockade,
  safe cells, finish and turn transitions.

### P0 — physical performance and lifecycle acceptance remains open

CI profile/release builds are useful build evidence, not performance evidence.
Cold/warm startup, UI/raster frame pacing, memory, battery, thermal behavior,
background/resume and repeated match navigation still require a real phone.
Use the profile APK and the protocol in
[Physical Android acceptance and performance](../DEVICE_ACCEPTANCE_AND_PERFORMANCE.md).

### P1 — match presentation/orchestration separation

`MatchScreen` is a large stateful widget (currently over 900 lines) combining
board rendering, gesture/selection behavior, animation coordination, AI turn
scheduling, lifecycle handling and local persistence. This is a maintainability
and regression-risk hotspot. The new `MatchSession` application boundary
centralizes accepted commands, actor checks, state-version checks and replay,
but the screen still owns presentation orchestration. Follow-up work should
extract a match controller/view-model and smaller board, dice, status and
result widgets without duplicating domain rules.

### P1 — strict formatting gate

The previous workflow ran `dart format --output=write`, which rewrote files in
the ephemeral CI checkout rather than failing when committed Dart files were
not formatted. The command is being changed to a non-mutating
`--output=none --set-exit-if-changed` check so formatting becomes a real gate.

### P1 — emulator integration evidence

Earlier project documentation described an Android emulator navigation test,
but the merged workflow did not contain an integration-test source file or an
emulator execution step. The current engineering branch adds both: a repeated
home → setup → local match → home smoke test and an API 34 emulator runner.
Its result must be green before treating that coverage as verified.

### P1 — product and accessibility scope

- Team Up is still disabled in setup; issue #19 remains open.
- Online multiplayer, social systems, matchmaking and live operations are not
  implemented. This is a local game foundation, not yet a Ludo King competitor.
- Hard AI is a stronger deterministic heuristic, not multi-turn search.
- Screen-reader semantics have automated coverage, but TalkBack navigation,
  text scaling, contrast and modal flows still need physical-device review.
- The current app version remains an early `0.1.0+1` foundation and should not
  be presented as a store-ready release.

## Recommended sequence

1. Merge and verify the command/session boundary and strict CI gates.
2. Complete Team Up behind a separate versioned mode/profile, sharing the same
   engine and session boundary; do not expose it before acceptance tests pass.
3. Extract the match controller and presentation widgets without changing
   gameplay semantics.
4. Complete native-resolution artwork review and physical-device gameplay,
   accessibility and performance acceptance.
5. Only then prepare a release candidate and store metadata.

## Release-readiness conclusion

The rebuild has a sounder architectural foundation and meaningful automated
coverage, but it is **not yet release-ready**. The blocking gaps are physical
visual/touch acceptance, real-device performance/lifecycle evidence, and the
unfinished Team Up mode if it remains in the first public product scope.

### P1 — match chrome and screenshot evidence

Reviewing the actual CI match-canvas image showed a polished premium board, but
also exposed two usability issues in the source UI: the baked-in Chat and More
artwork looked actionable without responding to taps, and the exit icon's
48-pixel design hitbox scaled below 44 logical pixels on a compact phone.

The session branch now:
- gives Chat an honest local-mode availability message;
- gives More working Restart (with confirmation) and Exit actions;
- expands the exit hitbox to preserve a usable physical target after scaling;
- captures both the entire 393×873 match screen and the separate 9:16 board
  canvas, instead of labelling a 393×699 canvas capture as a 393×873 screen.

The static portrait names and online indicators remain artwork content and are
not yet driven by the selected human/AI seat configuration. Before release,
replace or cover those baked labels with dynamic seat/status overlays without
editing the canonical source artwork.
