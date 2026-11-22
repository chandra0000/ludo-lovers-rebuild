# Premium gameplay implementation and release evidence

Production verdict: **NO-GO**. Implementation and automated verification are
separate from owner visual approval, simulator interaction and physical acceptance.
New PRs are unmerged; the current application on main is not this review stack.
The latest user instruction prohibits automatic merges and supersedes historical
Notion notes that permitted technical merges.

## Baseline, investigation and dependency graph

Primary repository: `chandra0000/ludo-lovers-rebuild`. Main audited at
`5dd35fb39efdbb22b50c1a549b41350e9b9f0e90`; application baseline
`4089a628ef528f55be35c5e9472ed63d08bfebe1`. Legacy is read-only behavioral evidence
at `ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`.

```text
main (application not promoted)
  #43 integrated presentation, includes #44 repair and #45 recovery
    → #46 readable HUD
      → #48 stable identity / names
        → #49 gold dice / glass pawns / feedback
          → #50 safe stars / ten responsive configurations
            → #51 restart / lifecycle
              → #52 confirmed exit / recovery
                → documentation evidence PR
#42: pawn work already reused; do not duplicate-merge its historical branch
#40: exterior halo reused; do not import its old HUD layout
#39: separate static renderer experiment, not a migration recommendation
#29: experimental calibration; preserve approved production geometry
#23: Team Up plan/session history, not an implemented rebuild Team Up engine
```

Review in the listed order; do not merge automatically. PR #43 and #46 retain
visual acceptance gates. The absence of #42's head as an ancestor does not mean
its equivalent pawn implementation is missing. The verified legacy feature matrix
and identity investigation are in [the program report](premium-gameplay-program-2026-11-16.md).

PR #43's original failures reached capture/encoding and then stalled on async
filesystem operations in widget fake time. The repair moves the complete
capture/I/O/decode transaction into `tester.runAsync`, uses deterministic
preferences and explicit image readiness, and disposes resources with bounded
diagnostics. No tests disabled or timeouts increased to conceal the cause.
[Original root-cause evidence](productionization-2026-11-16.md).

## Implementation and local evidence

| Phase | Delivered behavior | Local verification |
| --- | --- | --- |
| A | Reconciled PR dependencies, #45 integration and legacy source | Repository/source audit, prior Phase 0 green CI |
| B / #48 | Fixed Blue/Magenta HUD quadrants and baked portrait-ring assignments; stable roster and accent; Unicode human names and v3 saved roster | 313 tests; strict format and analysis |
| C / #49 | Authoritative gold cube, bounded roll and landing feedback; glass material polish; independent persistent sound/haptic/motion controls | 317 tests; all six dominant faces and interrupted-roll recovery |
| D / #50 | Removed duplicate star paint; eight canonical safe semantic anchors; portrait request; ten DPR/inset captures | 324 tests; artifact verifier, strict format and analysis |
| E / #51 | Classic restart/rematch retains profile; paused human command guards; observable serialized save outcome | Three regressions failed before fix, 327 tests passed after |
| F / #52 | Toolbar/menu/back confirmation; save success/failure/slow-storage feedback; cancel resumes accepted roll/AI | 334 tests passed in 84s; strict 145-file format and fatal-info analysis |
| G | Actual screenshots inspected; host engine diagnostic; evidence report and release gates | Device renderer measurements and physical acceptance blocked |

No gameplay rule, color-to-seat mapping, board topology or asset bytes changed.
Names have a documented 20-grapheme limit, preserve Unicode, reject blank/control
and problematic invisible input, and never serve as authoritative IDs. Two/three
human configurations still use four engine seats with remaining AI; this is not a
new variable-seat rule mode. Duplicate names retain visible seat identity.

## CI and build evidence

Every required job must conclude success; cancellation does not count.

| PR | Foundation workflow | Android/iOS workflow | Conclusion |
| --- | --- | --- | --- |
| #48 | [43806536145](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43806536145) | [43806536031](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43806536031) | VERIFIED COMPLETE: all required jobs succeeded |
| #49 | [43808309469](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43808309469) | [43808309416](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43808309416) | VERIFIED COMPLETE: all required jobs succeeded |
| #50 | [43997198229](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43997198229) | [43997198253](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43997198253) | VERIFIED COMPLETE: all required jobs succeeded |
| #51 | [43997897908](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43997897908) | [43997897771](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43997897771) | VERIFIED COMPLETE: all required jobs succeeded |
| #52 | [43998543984](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43998543984) | [43998544082](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43998544082) | VERIFIED COMPLETE: all required jobs succeeded |

Foundation checks enforce non-mutating format, analysis, complete unit/widget
suite, required PNG validation and artifact uploads. A dependent job builds split
profile/release APKs. Cross-platform checks build Android debug and unsigned iOS
simulator apps, plus macOS-rendered responsive widget captures. No job here proves
an installed app was interactively tested on a physical phone or iOS simulator.
Generated native runners remain a release-reproducibility limitation; pinning and
reviewing platform projects and signing configuration are still needed.

Final artifact receipt: [CI IDs, digests and successful job conclusions](evidence/ci-artifacts-9508b598-2026-11-17.json).

Downloaded final debug APK verifies with APK Signature Scheme v2, signed by
`CN=Android Debug`; package `com.ludolovers.ludo_lovers`, minSdk 24,
targetSdk/compileSdk 36. APK SHA-256:
`6f42b255f48e8bdfa05520fbf41469f940e5f59efdad6db0ac70b96e9aa3b4c4`.
This is not production signing or installation acceptance.

Downloaded final iOS simulator ZIP digest matches
`8b635341474feba21f7f828c14e2c983531365a0db6d74c20313f839ffa148d3`;
72 files include Runner and Info.plist. Bundle ID `com.ludolovers.ludoLovers`,
minimum iOS 13.0, supported platform `iPhoneSimulator`. Not executed locally.
Downloaded macOS screenshot ZIP digest matches
`71764068237093170f7b2ad0bc961af2ac53835080a4c85fce4b7c9f9b1cf97d`;
all ten PNGs pass validation and its 393×873 capture was visually inspected.

[Existing Notion project hub](https://www.notion.so/3f5d7b2be1cc81fea8f5f4b450a42160)
was updated using the Notion spec-to-implementation skill, preserving historical
notes and explicitly superseding prior automatic-merge permission.

## Screenshot and accessibility review

Actual Flutter-rendered captures exist for 320×640, 360×800, 393×873, 430×932;
all four were visually inspected. The 320×568 compact capture was also inspected.
Additional tested configurations: 375×667 DPR2; 393×873 DPR3 with 59/34 safe
insets; 440×956 DPR3 with 62/34 insets; 360×780 DPR2.75 with 32/24 insets;
600×1024 DPR2. Both logical padding and physical view padding are supplied.

Automated acceptance checks enforce no Flutter overflow, visible artwork,
profiles outside the board, names above square avatars, 48dp primary controls and
safe-area containment. The safe overlay paints no icons; approved artwork already
contains stars. Logical playable square remains `(17,205)–(559,747)` on the
576×1024 reference; the historical extracted artwork registration is unchanged.
Asset hashes, rather than a zero-difference claim across deliberately removed
star overlays or changed pawn shading, prove artwork preservation.

Review findings: seat identity and dice are clear; all required HUD regions fit
compact phones; gold cube depth is visible. The four legacy portraits are still
reused, the pawn detail is modest at small scales, and overall premium quality
requires owner comparison and device review. No 9/10 visual approval is claimed.
System and user reduced motion apply; essential choices have text/seat semantics
and a legal-pawn chooser, including stacked pawns. TalkBack/VoiceOver interaction,
measured contrast across animated artwork, maximum platform text settings and
physical touch acceptance remain unverified.

Preserved asset SHA-256 values:

- Full approved board: `f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`.
- Existing board extraction: `094ecd06ca5bbd89b86912d9a6418455dbfb3721ec990839a084e2f8bfabd85d`.
- Live brand icon: `ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793`.
- Separate logo asset: `778c6a53998c9fc243658d301e03cfb8f2e1ccfc4e71c7bc9d6225320f71aa97`.

No assets differ from the audited main baseline. The historical “logo hash” refers
to the live branding icon, not the separately named logo file.

## Performance evidence and measurement protocol

Production renderer remains Flutter. #39 is a static experimental harness;
there are no comparable animated physical-device Flutter/Flame results in this
program. Frame p50/p95/p99, dropped frames, process memory, startup/image decode
and 16-pawn/dice GPU cost remain **BLOCKED** on representative hardware.

A real host diagnostic was executed at application source
`9508b598d346d9beeb770a5a240f7a49f192301f` using Flutter 3.35.7 / Dart 3.9.2,
Linux Dart VM JIT, 2,000 warm-ups, 40 samples, 1,000 operations/sample.
[Raw JSON](evidence/engine-host-9508b598-2026-11-17.json). This is CPU/domain
microseconds per operation, not mobile frame performance or a renderer comparison.

| Host workload | Median µs/op | p95 µs/op |
| --- | ---: | ---: |
| initial_state_creation | 0.53 | 0.912 |
| legal_action_enumeration | 0.748 | 1.118 |
| single_move_evaluation | 0.154 | 0.496 |
| blockade_path_evaluation | 0.232 | 0.329 |
| transition_and_event_generation | 0.585 | 3.649 |
| capture_transition_and_events | 0.778 | 1.294 |
| snapshot_encode | 5.579 | 8.665 |
| snapshot_decode | 6.052 | 10.459 |
| seeded_ai_decision | 2.069 | 5.939 |

Device protocol (not yet executed): use the same physical phone, OS, pinned Flutter
version, profile build, renderer setting, board bytes, positions and seeded event
trace for both renderers. Warm up shaders/assets, record three 60-second runs per
scenario and retain raw frame timings/Perfetto traces. Cover static 16 pawns,
cell-by-cell movement, stacked selection, captures, home/finish, gold dice and
background/resume. Report build and raster distributions separately, display
refresh-rate budget, missed frames, memory before/peak/after, cold/warm startup
and decode durations. Record thermal/power state and test order. Compare screenshots
for coordinate/material parity. Retain Flutter unless measured improvements are
repeatable and do not regress visuals, architecture or maintenance.

## Twenty-deliverable status

VERIFIED COMPLETE means the named bounded deliverable has evidence; it does not
promote the entire application to production-ready.

| Deliverable | Status | Evidence or remaining gate |
| --- | --- | --- |
| 1 Repository audit | VERIFIED COMPLETE | Baseline/dependency audit and historical decision reconciliation |
| 2 Feature parity matrix | VERIFIED COMPLETE | Source-backed 20-row legacy/rebuild inventory in program report |
| 3 Player-color root cause | VERIFIED COMPLETE | Reproduced HUD quadrant and baked-ring mismatch, all-turn tests |
| 4 Dynamic names | VERIFIED COMPLETE | Live setup/game/results/restore, Unicode validation, v3 migration tests |
| 5 Premium pawns | IMPLEMENTED, AWAITING VERIFICATION | Automated tests pass; owner visual/device acceptance open |
| 6 Gold animated dice | IMPLEMENTED, AWAITING VERIFICATION | Six authoritative faces/lifecycle tests pass; device/visual acceptance open |
| 7 Safe-cell star validation | VERIFIED COMPLETE | Canonical eight-cell anchors, four painted stars, no duplicate icon layer |
| 8 Responsive Android/iOS screenshots | IMPLEMENTED, AWAITING VERIFICATION | Ten actual widget captures, Linux/macOS CI; physical/platform-interaction acceptance open |
| 9 Engine/gameplay regressions | VERIFIED COMPLETE | 334 local tests; selected profiles preserved, no rule changes |
| 10 Legacy migration summary | VERIFIED COMPLETE | Safe local feedback/settings/exit work; unapproved modes deferred explicitly |
| 11 Renderer benchmark results | BLOCKED | No representative physical hardware; host diagnostic kept separate |
| 12 CI workflow links | VERIFIED COMPLETE | Linked runs with job-level conclusions in CI section |
| 13 Android/iOS build evidence | VERIFIED COMPLETE | CI builds/artifacts and downloaded bundle checks; signing, interaction and physical release gates remain open |
| 14 PRs and commit SHAs | VERIFIED COMPLETE | Focused unmerged stack and file manifest below |
| 15 GitHub/Notion documentation | VERIFIED COMPLETE | Program, evidence report and existing Notion hub |
| 16 Outstanding blockers | VERIFIED COMPLETE | Explicit release gates below |
| 17 Final visual score | BLOCKED | Provisional engineering review 7/10; owner/device acceptance not complete |
| 18 Final engineering score | BLOCKED | Provisional review 7.5/10; release/device evidence incomplete |
| 19 Production-readiness verdict | VERIFIED COMPLETE | NO-GO; not production acceptance |
| 20 Recommended merge order | VERIFIED COMPLETE | Dependency graph, no automatic merges |

## Evidence-based provisional quality review

Scores describe observed readiness, not unmeasured device performance or final
owner acceptance. The full production program remains incomplete.

| Category | /10 | Basis and limitation |
| --- | ---: | --- |
| Architecture | 8 | Pure MatchSession/domain boundaries; UI orchestration remains substantial |
| Gameplay engine | 8 | Immutable/versioned/idempotent state and seeded AI tests |
| Gameplay correctness | 8 | Regression suite; physical long-match/process-kill acceptance open |
| Modes | 3 | Current/Classic implemented; Team Up/Quick/Tournament unavailable |
| UI/UX | 7 | Real responsive captures and named seats; owner review pending |
| Board rendering | 7.5 | Preserved assets/geometry, star duplication fixed; issue #41 acceptance open |
| Animation | 7 | Bounded authoritative sequences/recovery; device smoothness unmeasured |
| Accessibility | 6.5 | Semantics/chooser/48dp/motion tests; assistive-device and contrast review open |
| Performance readiness | 4 | Host diagnostic only; no GPU/device renderer comparison |
| CI/CD | 8 | Strict tests, artifacts and two-platform builds; runner/signing reproducibility open |
| Android readiness | 6 | Debug/profile/release build checks; physical/signing/AAB gates open |
| iOS readiness | 4.5 | Simulator compilation, macOS widget captures; no installed-app/physical acceptance |
| Overall production readiness | 5.5 | NO-GO until outstanding release gates pass |

## Release gates and next owner actions

- [ ] Review and merge the dependency stack manually after acceptance; main remains unchanged.
- [ ] Resolve issue #41's approved source/derivative visual decision; preserve assets meanwhile.
- [ ] Owner approve screenshots and representative physical Android/iOS UX.
- [ ] Run installed simulator interaction, real-device lifecycle/process-kill,
  long-match/restart soak, memory pressure, TalkBack/VoiceOver and cache/leak checks.
- [ ] Execute paired physical renderer benchmarks with raw evidence.
- [ ] Pin/review native projects; configure production signing; produce and verify
  Play-compliant AAB. Debug-signed APKs are not store release approval.
- [ ] Obtain complete versioned specifications before enabling missing modes.

## Exact source commits and changed files

These manifests list each focused commit relative to its parent, not the entire
stack. PR #44/#45 historical manifests are in the original productionization report.

### [PR #48](https://github.com/chandra0000/ludo-lovers-rebuild/pull/48)

Commit `ce4864bcf24f14e55c243bdb20ff4032a55c5989`.

```text
apps/mobile/lib/src/features/home/home_screen.dart
apps/mobile/lib/src/features/match/match_profiles_layer.dart
apps/mobile/lib/src/features/match/match_screen.dart
apps/mobile/lib/src/features/setup/game_setup_screen.dart
apps/mobile/lib/src/game/domain/match_player_profile.dart
apps/mobile/lib/src/game/domain/persistence/saved_match.dart
apps/mobile/lib/src/game/domain/player_name.dart
apps/mobile/lib/src/game/infrastructure/persistence/player_name_preferences.dart
apps/mobile/pubspec.lock
apps/mobile/pubspec.yaml
apps/mobile/test/engine_architecture_boundary_test.dart
apps/mobile/test/game_setup_ai_difficulty_test.dart
apps/mobile/test/identity/named_match_flow_test.dart
apps/mobile/test/identity/player_identity_persistence_test.dart
apps/mobile/test/identity/player_name_test.dart
apps/mobile/test/identity/player_seat_identity_test.dart
apps/mobile/test/integrated_match_presentation_test.dart
docs/quality/premium-gameplay-program-2026-11-16.md
```

### [PR #49](https://github.com/chandra0000/ludo-lovers-rebuild/pull/49)

Commit `36e5cbc500a35a33fa6118b80f6b10979688a143`.

```text
apps/mobile/lib/src/features/match/match_dialogs.dart
apps/mobile/lib/src/features/match/match_feedback.dart
apps/mobile/lib/src/features/match/match_feedback_settings.dart
apps/mobile/lib/src/features/match/match_landing_celebration.dart
apps/mobile/lib/src/features/match/match_screen.dart
apps/mobile/lib/src/game/domain/feedback_preferences.dart
apps/mobile/lib/src/game/infrastructure/persistence/feedback_preferences_store.dart
apps/mobile/lib/src/game/presentation/glassy_pawn.dart
apps/mobile/lib/src/game/presentation/luxury_dice.dart
apps/mobile/lib/src/game/presentation/shake_feedback_wrapper.dart
apps/mobile/test/luxury_dice_test.dart
apps/mobile/test/match_feedback_settings_test.dart
docs/quality/premium-gameplay-program-2026-11-16.md
```

### [PR #50](https://github.com/chandra0000/ludo-lovers-rebuild/pull/50)

Commit `5002c1477bb439a5331e433731e004e3f83dc9bb`.

```text
apps/mobile/lib/main.dart
apps/mobile/lib/src/features/match/match_safe_star_layer.dart
apps/mobile/lib/src/portrait_orientation.dart
apps/mobile/test/integrated_match_presentation_test.dart
apps/mobile/test/match_safe_star_layer_test.dart
apps/mobile/test/portrait_orientation_test.dart
apps/mobile/tool/verify_responsive_screenshots.py
docs/quality/premium-gameplay-program-2026-11-16.md
```

### [PR #51](https://github.com/chandra0000/ludo-lovers-rebuild/pull/51)

Commit `839a66ca2e6e309d63569bdd2521186e4d398f56`.

```text
apps/mobile/lib/src/features/match/match_persistence_controller.dart
apps/mobile/lib/src/features/match/match_screen.dart
apps/mobile/test/app_test.dart
apps/mobile/test/match_persistence_controller_test.dart
apps/mobile/test/match_restart_lifecycle_test.dart
docs/quality/premium-gameplay-program-2026-11-16.md
```

### [PR #52](https://github.com/chandra0000/ludo-lovers-rebuild/pull/52)

Commit `9508b598d346d9beeb770a5a240f7a49f192301f`.

```text
apps/mobile/integration_test/app_navigation_test.dart
apps/mobile/integration_test/app_smoke_test.dart
apps/mobile/lib/src/features/match/match_dialogs.dart
apps/mobile/lib/src/features/match/match_screen.dart
apps/mobile/test/app_test.dart
apps/mobile/test/match_exit_confirmation_test.dart
docs/quality/premium-gameplay-program-2026-11-16.md
```
