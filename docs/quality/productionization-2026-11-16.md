# Productionization evidence and dependency ledger — 2026-11-16

## Baseline and authority

Implementation repository: `chandra0000/ludo-lovers-rebuild`; legacy is reference-only.
Main audited SHA: `4089a628ef528f55be35c5e9472ed63d08bfebe1`.
PR #43 remote branch at checkout: `28fc71ec2cd9b308e351d40af59a2b0cc7935138`.
GitHub connector metadata initially reported its preceding SHA `928f791a38eebc6f9830b20d0a53fe444db72754`;
`git ls-remote` confirmed the newer timeout/concurrency commit. The repair includes it.

Authority order: explicit current owner instructions, recorded approved decisions,
then current code and regression evidence. Research proposals are not approvals.
The owner's latest instruction permits automatic merging when verified; this
supersedes the earlier no-automatic-merge instruction, but does not waive visual,
rule, device, review-thread, or required-check gates.

Read alongside `docs/DECISIONS.md`, `docs/engineering/match-session-boundary.md`,
the premium visual acceptance document, and the connected Notion Project Hub,
Local Classic release audit, and Player Research/Visual Plan.

### Documentation conflicts resolved without changing product behavior

- Older architecture/status/rules pages describe pre-session direct transitions,
  missing persistence, or already-merged PRs as pending. Current code and git history
  establish implemented boundaries; that does not establish product acceptance.
- PR #24 and #26 were merged historically; #26's visual composition was subsequently
  reverted in #30. Do not restore it or promote #29 merely because historical notes
  recommend their integration.
- The current default is `ludo-lovers-current@1`; `classic@1` remains opt-in.
  Historical references to Classic do not authorize changing that default.
- The 576×1024 logical geometry and its approved diagonal transitions are preserved.
  The existing board derivative has a separate asset rectangle; this repair changes
  only the decorative halo, not that rectangle, artwork, topology, or pawn anchors.
- Old 44dp accessibility proposals do not override the current 48dp requirement.

## Existing PR dependency graph

```text
main 4089a62
  +-- #42 premium pawn lighting --> #43 integrated presentation
  |                                  +-- Phase 0 responsive/CI repair
  +-- #40 exterior halo + accessible controls (separate draft)
  +-- #39 static Flutter/Flame experiment (separate draft)
  +-- #23 Team Up (conflicting draft; depends on validated engine baseline)
  +-- #12 historical formatter diagnostics (not required for this repair)

historical #24 --> #26 --> #29 optional mask
                    |
                    +-- #30 reverted visual composition
```

PR #43 includes #42's implementation in its ancestry; do not integrate the same
lighting twice. The Phase 0 repair reuses only #40's exterior halo and strengthens
its transparency test to native 576×1024 resolution. #40's separate match-control
changes are not included or implicitly accepted. Its remaining diff needs review
against the integrated baseline. #29 stays experimental and disabled; #39 does
not justify a production renderer change. #23 requires conflict resolution and
issue #19's dedicated behavior/snapshot tests before availability.

## PR #43 responsive timeout: root cause and controlled reproduction

Historical acceptance run:
https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43561450428

On macOS, all four cases reached the ten-minute test timeout; no responsive PNGs
were uploaded and the simulator build was skipped. The Android job was cancelled.
A successful artifact-upload *step* with a no-files warning was not evidence of an
artifact. Foundation run `43561450464` was also cancelled.

Instrumented local reproduction on pinned Flutter 3.35.7 / Dart 3.9.2, Linux x64:

```text
initialize
assertions
capture
encode
write
create directory
[no completion; diagnostic process terminated at its external cap]
```

The first blocked operation was `await output.parent.create(recursive: true)` in
Flutter's fake-async widget-test zone. Initialization, layout assertions,
`RenderRepaintBoundary.toImage`, and PNG encoding had completed. This excludes
those earlier stages as the cause of that reproduced hang. There is no
`pumpAndSettle` in this test.

Moving filesystem work alone allowed the body to complete but left the case
stalled at test completion. Moving the complete capture/encode/write lifecycle
into `tester.runAsync`, mocking SharedPreferences, and explicitly unmounting and
pumping before resetting view metrics completed all four cases. Engine/image
callbacks and real I/O now complete in the appropriate async context. Images and
codecs are disposed in `finally`; each external stage has a real ten-second bound,
and each test has a shorter sixty-second overall guard. No timeout was increased
and no failing assertion was disabled.

The final fixture awaits actual image-provider readiness rather than sleeping,
loads the pinned SDK's Roboto/MaterialIcons for readable Android-style PNGs,
asserts avatar geometry and safe areas, and decodes each written PNG to verify
its dimensions. These are actual software-rendered Flutter screenshots, not
physical Android screenshots or iOS rendering acceptance.

### Additional failure exposed by the full suite

`match_board_focus_frame_test.dart` failed because #43's square decorative frame
ended above the rendered artwork's bottom edge (603.66 versus 613.90 in the test
viewport). Reused #40's exterior-only clipped painter instead of weakening the
coverage assertion or moving artwork/pawns. Native-resolution alpha scanning
checks every strictly interior pixel remains transparent in the isolated halo.

## Verification at the repaired candidate

- **VERIFIED COMPLETE:** strict formatting, 125 Dart files with zero changes.
- **VERIFIED COMPLETE:** fatal-infos Flutter analysis, no issues.
- **VERIFIED COMPLETE:** full unit/widget suite, **290 tests passed**, 82 seconds
  on this runner. This is not a mobile performance measurement.
- **VERIFIED COMPLETE:** PNG capture/decode at 320×640, 360×800, 393×873, 430×932.
- **VERIFIED COMPLETE:** standalone artifact verifier accepts all four PNGs and
  rejects missing, corrupt, and incorrectly sized examples.
- **VERIFIED COMPLETE:** canonical board SHA-256 remains
  `f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`;
  logo remains `ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793`.
- **IMPLEMENTED, AWAITING VERIFICATION:** updated GitHub Actions on the published
  head; Android debug/profile/release and iOS simulator build gates.
- **BLOCKED:** physical-device acceptance and owner visual/rule acceptance have
  no recorded evidence. No production-readiness claim is made.

Local logs and generated PNGs live in ignored `apps/mobile/test-artifacts/`.
CI uploads responsive PNGs and fails if a required file is missing or corrupt.

## CI changes and reproduction

App dependencies are locked. PR verification now includes stacked PR bases;
branch pushes do not duplicate PR workflows. Main pushes and manual dispatch
remain supported. Concurrency serializes each ref without cancelling active work.
Formatting verification no longer runs a source-mutating diagnostic formatter.
Linux runs the full suite once; macOS retains the focused responsive/event suite
for platform parity. Android acceptance now generates its missing runner before
building, matching the foundation workflow. Pinned platform projects remain a
later release-engineering task; CI generation is a documented interim measure.

```sh
cd apps/mobile
flutter pub get
# Flutter 3.35.7 / Dart 3.9.2
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter analyze --fatal-infos
flutter test --reporter expanded
python3 tool/verify_responsive_screenshots.py
```

## Dependency-aware remaining program

| Phase | Work and required evidence | Status |
| --- | --- | --- |
| 0 | Published repair, every required CI job green, inspected screenshots, validated integration baseline | IMPLEMENTED, AWAITING VERIFICATION |
| 1 | Audit existing controllers/session; close demonstrated lifecycle/idempotency/replay gaps with tests; preserve snapshot migrations | NOT STARTED |
| 2 | Reconcile #40; preserve art/geometry; adaptive profiles/dice/social regions, 48dp controls, accessible stacks; actual viewport + phone review | NOT STARTED |
| 3 | Event-driven dice/move/capture/finish, bounded cancellation/recovery, local reactions; deterministic ordering/interrupt tests | NOT STARTED |
| 4 | Profile regression matrix; reconcile #23; Quick/Tournament unavailable without approved specifications | NOT STARTED |
| 5 | Extend #39 with identical 16-pawn scenarios; comparable physical-device timings/memory/startup; retain Flutter unless evidence supports change | NOT STARTED |
| 6 | Pinned Android/iOS projects, APK/AAB, simulator runtime, secure signing, accessibility/lifecycle/soak/device acceptance | NOT STARTED |
| 7 | Evidence-linked architecture/rules/geometry/test/CI/performance/release docs and thirteen-category scored audit | NOT STARTED |

Do not start dependent phases until Phase 0's required CI gates pass. A phase may
need several focused PRs. Integrate only a current checked SHA with resolved
review blockers; do not force-push or erase another branch. Keep visual/physical
acceptance separate from technical test success. Quick/Tournament specifications,
physical devices, signing credentials and visual approval are external gates,
not invitations to invent behavior or measurements.

## Release decision

**NO-GO.** This is a verified local Phase 0 correction awaiting remote/platform
verification, not completion of the productionization program. No benchmark
comparison, physical-device result, signed release, simulator runtime result, or
9/10 visual/readiness score is implied.

## Phase 0 remote verification and integration

Repair PR [#44](https://github.com/chandra0000/ludo-lovers-rebuild/pull/44)
passed all four check runs on `89956ef638318ef3257ed34e4734c62e446335d9`:

- [Foundation workflow](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938): verification and Android profile/release APKs **success**.
- [Cross-platform workflow](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929): Android debug APK and iOS simulator build **success**.
- [Linux responsive PNG artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938/artifacts/14195352863).
- [macOS responsive PNG artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929/artifacts/14194644195): downloaded, all four CRC/dimension checks passed; smallest capture inspected.
- [Debug APK artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929/artifacts/14195720944).
- [Profile APK artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938/artifacts/14195347381).
- [Release APK artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467938/artifacts/14196015445).
- [Unsigned simulator app artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43798467929/artifacts/14195496597).

No review threads or reviews blocked #44. Per owner authorization it was merged
**into draft #43's branch**, producing `32b2ce50bd066d3bf9ec4c206d5ea23e21a56dc6`.
The merge tree exactly matches the checked repair tree
`12c87431a4363f5b851221395f65d886e5ee05c1`. This is the Phase 1 integration baseline;
main and #43's visual/device acceptance remain unchanged. Phase 0 technical gates
are now **VERIFIED COMPLETE**. A simulator build is not simulator interaction or
physical iOS acceptance. Generated release APKs are not production-signed releases.

Local Android verification additionally attempted the CI-equivalent generated
project in an isolated copy. Gradle required explicit proxy configuration, then
failed because the installed Java runtime has no Java compiler. The remote
Android build evidence above is green; local build failure is recorded rather
than claimed as a pass. No generated project files entered the implementation repo.

## Phase 1 implementation and regression evidence

Audit found a human recovery deadlock: initialization only completed restored
rolls for AI seats. A restored human roll of two with every pawn in its yard had
no legal pawn, no roll action and no scheduled pass. With the original condition,
`restored_human_turn_test.dart` fails: expected Green after the pass delay, actual
Orange. Restoring the general pending-roll handler passes that regression, without
rerolling or changing engine rules. A second test interrupts an automatic single
legal move, resumes, and checks exactly one version increment/move across repeated
pause/resume notifications.

Moved SharedPreferences I/O out of domain into infrastructure. The saved DTO/codecs
remain pure; schemas, storage key and migrations are preserved. Saved AI-seat sets
are copied and frozen to prevent mutation between enqueue and asynchronous write.
An import-boundary regression enforces package-free domain/application layers and
prevents domain-to-application/presentation dependencies. Existing authoritative
session, controller, engine, dice RNG, artwork and geometry are preserved.

The targeted recovery, architecture, store and queued-persistence tests pass
locally (10 tests). Full-suite and remote acceptance will be recorded on the
published Phase 1 commit. This is not physical process-kill acceptance.

Phase 1 local final verification: **294 tests passed** in 72 seconds, strict
formatting **128 files, zero changes**, fatal-infos analysis **no issues**.
Two existing widget fixtures now explicitly represent pawn-selection state:
accessibility flushes the restored-roll presentation frame, and blockade feedback
keeps two alternative legal pawns so an automatic single move/pass cannot consume
its inspection turn. Assertions remain intact; the new recovery tests cover the
previously stranded automatic path.

Downloaded Phase 0 debug APK: SHA-256
`8d09e06a8575bb89d8f68f42690c78c5cd8bceecca267220100ff795c1fc227f`.
`apksigner verify --verbose --print-certs` passes (v2 signature); `aapt dump badging`
reports `com.ludolovers.ludo_lovers`, versionCode 1 / versionName 0.1.0,
minSdk 24 / targetSdk 36 / compileSdk 36. It is debug-signed, not a release
acceptance artifact. No physical installation is claimed.

## Phase 1 remote verification and integration

PR [#45](https://github.com/chandra0000/ludo-lovers-rebuild/pull/45) passed all four
required jobs on `db89b27b66b69f8cc1d2cd06a41a1f1b07a00d4a`:
[foundation](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43800187634)
and [Android/iOS acceptance](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43800187677).
No review submissions or unresolved threads blocked it. It was merged into #43's
integration branch as `a1ef5846d2a5f4fe3f66b1e9ee344c93c4e626bb`, with the identical
checked tree `ba19bc11e135429567d0e4d6fb97ca83036ba8f4`. Phase 1 code and automated
acceptance are **VERIFIED COMPLETE**; physical process interruption remains a
separate device gate. Main remains unchanged.

## Phase 2 presentation increment

Addresses observed screenshot issues without changing approved art or pawn geometry:

- Names render at 14dp before user text scaling and use the full profile width;
  square avatars render at 40dp (32dp with 150% text). LOCAL/BOT labels and gold
  active-turn feedback remain. Growth is bounded in constrained diagnostics.
- Top and bottom profile regions remain outside the existing artwork rectangle.
  Profile glow and rolling-die effects are clipped away from protected artwork.
- Enlarged 120×120 design-space dice target and 96-unit cube retain authoritative
  values and the existing animation; no second die or different outcome source.
- Next action (Roll dice / Rolling dice / Choose a pawn / Pawn moving / No legal
  move / AI thinking / Match finished) is explicit beside the existing turn label.
- The action dock becomes a legal-pawn popup when there are multiple human choices.
  It dispatches the existing selection command, including for adjacent/stacked
  choices; it does not evaluate rules. Local chat/reactions remain local.
- Exit and pawn hitboxes meet 48dp after scaling. Existing social controls remain.
  The responsive test now uses `getRect` for **transformed** control bounds instead
  of `getSize`, which only checked the unscaled design-space render box.

The artwork registration is exposed as one presentation constant with identical
numeric values, not a new geometry mapping. All four initial-state captures have
**zero changed RGB pixels** in the fully interior board region versus the Phase 1
baseline using the same state, fonts, insets and viewport. The exact regions and
counts are recorded in [the pixel comparison](evidence/phase2-board-pixels-2026-11-16.json).
This proves preservation by this increment, not approval of the existing derivative
against the immutable full portrait source; issue #41 remains relevant.

New checks cover 150% text at 320×640 and 430×932, actual >=48dp exit/dice/chooser
bounds, complete legal-pawn popup selection with exactly one roll/move, and native
576×1024 alpha transparency inside the board during profile glow and rolling dice.
Existing landscape diagnostics remain supported without changing portrait geometry.

Actual screenshots were inspected at all four requested sizes. Names and next
actions are visibly larger; all profiles and the complete board remain visible.
No 9/10 visual acceptance, TalkBack/device acceptance or production release is
claimed. Owner screenshot review and 6.1–6.9-inch physical Android evidence remain
required before promoting the presentation to main.

### Scope of remaining mode evidence

Read the actual diff and documentation in #23, rather than its title: it contains
a Team Up **implementation plan** and historical MatchSession work, not a shipped
Team Up engine. Current main already incorporates the session boundary via other
work. Do not blindly integrate the old branch or describe Team Up as implemented.
Issue #19 and the plan specify its acceptance matrix; mode availability remains
blocked until engine/UI/persistence integration and owner/device acceptance.
Quick and Tournament behavior still lacks an approved executable specification.

### Runtime limitations found

The current entry point does not explicitly lock orientation. Production portrait
configuration and native platform project pinning remain Phase 6 work; the Phase 2
layout checks do not establish a runtime orientation guarantee. Physical Android,
iOS simulator interaction, physical iOS, signed AAB, and Flutter-versus-Flame device
measurements remain unexecuted. Retain Flutter as production renderer.

Phase 2 local final gates: **298 tests passed** in 103 seconds, fatal-infos analysis
**no issues**, strict formatting **131 files with zero changes**, and all four PNG
integrity/dimension checks passed. Runtime/native/device claims remain separate.
