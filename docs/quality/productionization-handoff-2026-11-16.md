# Ludo Lovers productionization handoff — 2026-11-16

## Release decision and completed work

**NO-GO for production release.** Phases 0–1 have verified code/automated gates.
Phase 2 is implemented as a separate visual-review draft. Its screenshot acceptance
and physical-device gates remain open. Dependent phases 3–7 are not complete.
This report is an interim engineering handoff, not the final Phase 7 quality audit.

Rebuild is the only implementation repository. Audited main application baseline:
`4089a628ef528f55be35c5e9472ed63d08bfebe1`. Legacy was not imported or modified.
Implementation and technical merges are on draft #43's integration branch; these
changes have not promoted its application code to main. This documentation PR adds
only the evidence handoff to main.

### Root causes fixed

1. PR #43's responsive cases awaited asynchronous directory creation inside
   Flutter's fake-async widget test. Instrumented reproduction reached initialize,
   assertions, capture and PNG encoding, then stopped at directory creation.
   Capture/encoding/I/O now run together in `tester.runAsync`, with bounded asset
   readiness, deterministic preferences/teardown, image/codec disposal and decoded
   PNG checks. No test was disabled and no timeout increased.
2. The full suite then exposed a halo ending above the board. Reused #40's
   exterior-only painter and added native-resolution interior-alpha verification.
   Board/pawn positions were not moved to satisfy the test.
3. A restored human roll with no legal pawn never scheduled its pass: initialization
   restored only AI dice presentation. The regression fails with the original
   condition (Orange stays active) and passes with the fix (one engine pass to Green).
   Repeated resume cannot reroll or duplicate the delayed move.
4. SharedPreferences lived in a domain file and queued snapshots could observe a
   caller-mutated AI-seat set. The DTO is pure, the adapter is in infrastructure,
   and snapshot seat sets are copied/frozen. Persisted schemas/key remain unchanged.

### Phase status

| Phase | Status | Evidence or remaining gate |
| --- | --- | --- |
| 0 | VERIFIED COMPLETE | 290 tests, strict format/analyze, four PNGs, Android debug/profile/release and iOS simulator builds; #44 integrated |
| 1 | VERIFIED COMPLETE | 294 tests, architecture import guard, reproduced recovery fix, snapshot/queued-save tests, Android/iOS CI; #45 integrated |
| 2 | IMPLEMENTED, AWAITING VERIFICATION | 298 local tests and inspected screenshots; owner visual and physical-device acceptance remain open |
| 3 | NOT STARTED | Existing animations retained/tested, but the requested coordinated refinement program has not advanced past Phase 2 acceptance |
| 4 | NOT STARTED | Existing compatibility/Classic regression suites pass; Classic product approval and Quick/Tournament specs remain open; #23 is a plan, not an implemented Team Up engine |
| 5 | NOT STARTED | #39 is a static experimental harness; no comparable animated 16-pawn physical-device results |
| 6 | NOT STARTED | Compilation artifacts exist, but pinned native projects, explicit portrait runtime configuration, simulator interactions, signing, AAB and device acceptance remain unfinished |
| 7 | NOT STARTED | Final thirteen-category quality audit requires the preceding implementation and evidence |

"Verified" for Phases 0–1 means the recorded code/automated gates, not physical
process-kill, device performance, signed-distribution or owner product acceptance.

## PRs, exact commits and merge order

| PR | Reviewed scope | Source commit | Integration |
| --- | --- | --- | --- |
| [#44](https://github.com/chandra0000/ludo-lovers-rebuild/pull/44) | Responsive capture, CI artifact gates, exterior halo | `89956ef638318ef3257ed34e4734c62e446335d9` | Merged into #43 as `32b2ce50bd066d3bf9ec4c206d5ea23e21a56dc6` |
| [#45](https://github.com/chandra0000/ludo-lovers-rebuild/pull/45) | Restored human turns and pure persistence boundary | `db89b27b66b69f8cc1d2cd06a41a1f1b07a00d4a` | Merged into #43 as `a1ef5846d2a5f4fe3f66b1e9ee344c93c4e626bb` |
| [#46](https://github.com/chandra0000/ludo-lovers-rebuild/pull/46) | Readable profiles, existing die, explicit next action and legal-pawn chooser | `d2054308a0b820e9b8757637ccf7b0074ddbb37b` | Draft; visual/device gates open |

Technical merges were authorized by the owner's latest instruction. No force-push
or automatic visual merge occurred. Each merged technical tree exactly matches its
checked PR tree. Main app code remains at the audited baseline.

Dependency order: #44 → #45 are integrated into #43. Review #46 against that
baseline, then obtain #43/#46's remaining visual/source/device acceptance before
promotion to main. #42's pawn source/tests match the integration branch byte for
byte, but #42's final head is **not** an ancestor; reconcile its remaining metadata
rather than applying the pawn implementation twice. #40's halo, 48dp pawn targets
and legal-pawn-choice intent have been reused; its old overlay placement must not
be blindly merged over #46. #29 stays an opt-in calibration experiment; #39 stays
experimental; #23 requires actual Team Up implementation, conflict reconciliation
and its complete rule/session/snapshot/UI acceptance matrix.

Historical correction: #24/#26 were merged, and #26's visual composition was
subsequently reverted in #30. Old Notion/status instructions to merge them are
historical, not authorization to restore the reverted composition.

## Verification and artifact registry

Pinned environment: Flutter 3.35.7, Dart 3.9.2. Local Linux x64 execution:

- Phase 0: 290 tests / 82 seconds; 125 formatted Dart files; no analyzer issues.
- Phase 1: 294 tests / 72 seconds; 128 formatted Dart files; no analyzer issues.
- Phase 2: 298 tests / 103 seconds; 131 formatted Dart files; no analyzer issues.

These durations describe host test runs, not game frame-time measurements.
The full suites include rules/profile, session idempotency/version/replay,
geometry, AI, saved-state, lifecycle, dice, movement, local social and widget checks.
No test result for an unimplemented mode is implied.

| Candidate | Foundation workflow | Android/iOS workflow | Conclusion |
| --- | --- | --- | --- |
| #44 | [43798467938](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938) | [43798467929](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929) | Both success, all four jobs passed |
| #45 | [43800187634](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43800187634) | [43800187677](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43800187677) | Both success, all four jobs passed |
| #46 | [43802196713](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196713) | [43802196676](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196676) | Both success, all four jobs passed |

Phase 0 artifacts (verified registry; no cancelled run is counted as success):

- [Four Linux responsive PNGs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938/artifacts/14195352863).
- [Four macOS responsive PNGs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929/artifacts/14194644195): downloaded, CRC/dimensions checked and smallest image inspected.
- [Debug APK](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929/artifacts/14195720944).
- [Profile APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938/artifacts/14195347381).
- [Release APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938/artifacts/14196015445).
- [Unsigned iOS simulator app](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929/artifacts/14195496597).

Downloaded debug APK SHA-256:
`8d09e06a8575bb89d8f68f42690c78c5cd8bceecca267220100ff795c1fc227f`.
Android `apksigner` verifies its v2 signature; `aapt` reports package
`com.ludolovers.ludo_lovers`, version `0.1.0+1`, minSdk 24, compileSdk/targetSdk 36.
It is debug-signed. No physical installation, release keystore, Play upload or
signed release AAB acceptance is claimed.

Local Android build attempts were recorded, not hidden: the initial Gradle client
needed proxy configuration; after that the installed Java runtime lacked a compiler.
The isolated local build failed. Remote Android CI builds above passed. Generated
platform files did not enter the implementation source tree.

Latest Phase 2 artifacts, source `d2054308a0b820e9b8757637ccf7b0074ddbb37b`:

- [Four Linux responsive screenshots](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196713/artifacts/14197355754).
- [Four macOS responsive screenshots](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196676/artifacts/14196782328).
- [Debug APK](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196676/artifacts/14197096896), downloaded and signature/package verified; SHA-256 `917b80db3c40397b01c939d3baa84dcecca9b7a1ad53ffba02115c0deb73eaad`.
- [Profile APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196713/artifacts/14196668748).
- [Release APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196713/artifacts/14197446267).
- [Unsigned iOS simulator app](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196676/artifacts/14196787806).

All four required jobs on #46 are green. Its remaining acceptance concerns visuals,
board-source provenance and physical devices; it remains a draft, unmerged.

### Screenshot and artwork evidence

Actual Flutter-rendered PNGs cover 320×640, 360×800, 393×873 and 430×932 with
24dp top/bottom insets. Font fixtures load the pinned SDK's Android-style fonts;
these images do not represent physical Android or native iOS visual acceptance.
All four final captures were inspected and decoded. The Phase 2 comparison records
zero changed protected board-interior RGB pixels against the verified Phase 1
baseline at all four viewports. Its manifest is in #46 at
[the exact pixel comparison manifest](https://github.com/chandra0000/ludo-lovers-rebuild/blob/d2054308a0b820e9b8757637ccf7b0074ddbb37b/docs/quality/evidence/phase2-board-pixels-2026-11-16.json).

Canonical board SHA-256 is unchanged:
`f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`.
Canonical bundled logo SHA-256 is unchanged:
`ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793`.
The existing derivative/approved-source relationship in issue #41 still needs
acceptance. This program has not regenerated, cropped, stretched or replaced art.

### Accessibility evidence and limits

Phase 2 checks global transformed control bounds, not unscaled design-box sizes.
Exit, roll, social actions and the legal-pawn chooser meet the tested 48dp minimum.
Adjacent/stacked choices can use a legal-pawn popup, with one accepted move per
selection. Names sit above square avatars, statuses do not fake online service,
150% text tests pass on compact/large portraits, and HUD glow/dice motion paint no
pixels inside the protected board in a native-resolution regression.

TalkBack, physical touch accuracy, real-device text/display scaling, quantitative
contrast and final reduced-motion flows still require acceptance. Screenshots and
semantics tests do not establish full accessibility compliance.

## Requested deliverable status

| # | Deliverable | Status | Evidence/limit |
| --- | --- | --- | --- |
| 1 | Repository baseline audit | VERIFIED COMPLETE | Main/PR/issue/CI/source and accessible project-note audit recorded |
| 2 | Failure root-cause analysis | VERIFIED COMPLETE | Reproduced directory-create hang; halo and human restore failures covered |
| 3 | All-phase implementation | IMPLEMENTED, AWAITING VERIFICATION | Phases 0–1 verified, Phase 2 awaiting acceptance; 3–7 not started |
| 4 | Implementation PR links | VERIFIED COMPLETE | #44, #45, #46 above |
| 5 | Commits and changed files | VERIFIED COMPLETE | Exact parent/source/merge SHAs and manifests below |
| 6 | CI/test evidence | VERIFIED COMPLETE | Remaining device/runtime gates are separate |
| 7 | Android APK build evidence | VERIFIED COMPLETE | CI artifacts; debug APK downloaded/signature and metadata verified |
| 8 | iOS simulator build evidence | VERIFIED COMPLETE | CI build/artifact; no simulator interaction or physical iOS claim |
| 9 | Responsive screenshots | VERIFIED COMPLETE | Four actual Flutter captures; owner acceptance remains open |
| 10 | Flutter-versus-Flame results | NOT STARTED | Static #39 is not an animated/device comparison; no numbers fabricated |
| 11 | Gameplay regression report | VERIFIED COMPLETE | Full suite passes; Team Up/Quick/Tournament are not implemented |
| 12 | Accessibility acceptance | IMPLEMENTED, AWAITING VERIFICATION | Bounds/text/semantics checks pass; TalkBack/device/contrast acceptance open |
| 13 | Physical-device acceptance | BLOCKED | No physical Android or iOS device available to this execution |
| 14 | GitHub and Notion documentation | VERIFIED COMPLETE | Architecture/evidence ledger and existing Notion Project Hub updated |
| 15 | Final readiness score | BLOCKED | Final audit lacks required visual/device/performance/release evidence; no invented 9/10 |
| 16 | Blockers and merge order | VERIFIED COMPLETE | Explicit dependencies and open gates above/below |

## Remaining blockers and next authorized work

1. Owner HUD screenshot acceptance for #46 is requested and pending; source/board
   acceptance in #41 remains distinct. Do not silently approve or merge visuals.
2. Physical Android (including low-memory and representative 6.1–6.9-inch phones)
   and iOS devices are unavailable. Record model/OS/RAM/SHA, actual touch/lifecycle,
   long matches/rematches, image-cache/memory/frame/startup traces when available.
3. Classic profile remains opt-in pending approved rules. Quick/Tournament require
   complete approved specifications. #23 does not contain a Team Up engine.
4. Do not select Flame without comparable 16-pawn scenarios and physical-device
   measurements. Keep Flutter as production renderer.
5. Native Android/iOS projects, explicit portrait runtime configuration, launcher
   identity review, simulator interaction, secure release signing/AAB, store and
   device acceptance remain Phase 6 work. Signing/account credentials are external.
6. Final Phase 7 thirteen-category scoring and production approval remain blocked
   until the program and its evidence gates are complete.

The full source-side ledger is maintained on the implementation branch at
`docs/quality/productionization-2026-11-16.md`. Existing project notes are updated
at [Notion Project Hub](https://app.notion.com/p/3f5d7b2be1cc81fea8f5f4b450a42160).
Do not overwrite approved decisions to clear these gates.

## Exact changed-file manifests

Statuses below are git name-status output; R069 is a detected rename/split.

### PR #44

Commit: `89956ef638318ef3257ed34e4734c62e446335d9`. Parent: `28fc71ec2cd9b308e351d40af59a2b0cc7935138`.

```text
M	.github/workflows/cross-platform-acceptance.yml
M	.github/workflows/flutter.yml
M	.gitignore
M	apps/mobile/lib/src/features/match/match_board_focus_frame.dart
A	apps/mobile/pubspec.lock
M	apps/mobile/test/integrated_match_presentation_test.dart
M	apps/mobile/test/match_board_focus_frame_test.dart
A	apps/mobile/test/support/load_sdk_fonts.dart
A	apps/mobile/tool/verify_responsive_screenshots.py
M	docs/README.md
A	docs/quality/productionization-2026-11-16.md
```

### PR #45

Commit: `db89b27b66b69f8cc1d2cd06a41a1f1b07a00d4a`. Parent: `32b2ce50bd066d3bf9ec4c206d5ea23e21a56dc6`.

```text
M	apps/mobile/lib/src/features/home/home_screen.dart
M	apps/mobile/lib/src/features/match/match_persistence_controller.dart
M	apps/mobile/lib/src/features/match/match_screen.dart
R069	apps/mobile/lib/src/game/domain/persistence/saved_match_store.dart	apps/mobile/lib/src/game/domain/persistence/saved_match.dart
A	apps/mobile/lib/src/game/infrastructure/persistence/saved_match_store.dart
A	apps/mobile/test/engine_architecture_boundary_test.dart
M	apps/mobile/test/home_resume_test.dart
M	apps/mobile/test/match_accessibility_test.dart
M	apps/mobile/test/match_invalid_move_feedback_test.dart
M	apps/mobile/test/match_persistence_controller_test.dart
A	apps/mobile/test/restored_human_turn_test.dart
M	apps/mobile/test/saved_match_store_test.dart
M	docs/architecture/architecture.md
M	docs/quality/productionization-2026-11-16.md
```

### PR #46

Commit: `d2054308a0b820e9b8757637ccf7b0074ddbb37b`. Parent: `a1ef5846d2a5f4fe3f66b1e9ee344c93c4e626bb`.

```text
M	apps/mobile/lib/src/features/match/match_board_artwork.dart
M	apps/mobile/lib/src/features/match/match_dice_layer.dart
M	apps/mobile/lib/src/features/match/match_hud_overlay.dart
A	apps/mobile/lib/src/features/match/match_hud_region_clipper.dart
M	apps/mobile/lib/src/features/match/match_profiles_layer.dart
M	apps/mobile/lib/src/features/match/match_screen.dart
M	apps/mobile/test/integrated_match_presentation_test.dart
A	apps/mobile/test/match_adaptive_controls_test.dart
A	apps/mobile/test/match_hud_artwork_protection_test.dart
A	docs/quality/evidence/phase2-board-pixels-2026-11-16.json
M	docs/quality/productionization-2026-11-16.md
```
