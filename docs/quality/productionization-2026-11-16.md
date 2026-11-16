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
