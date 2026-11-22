# Premium Match V2 — engineering acceptance report

Checkpoint: 2026-11-18. **Production verdict: NO-GO.** Local features are implemented
in a review stack; no new PR has been merged. Public builds retain compatibility
mode and gate Classic/Quick/Team previews pending acceptance. Automated checks,
visual inspection, owner approval and physical-device acceptance are distinct.

## Source, dependencies and exact changes

Baseline main: `879f2b555c50575c5db066e0ac8bf530271a965a`.
Legacy behavior reference: `ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`.
Latest application source: `2822cb969e8906f4c3b7ed093906dc0764badb6d` (#63).
Online design: `608a92eb017760041826667de18f480a118e0e97` (#64).

The [source manifest](evidence/premium-v2-source-manifest-2026-11-18.json)
contains exact published source SHAs, tree SHAs, every changed file per PR and
workflow URLs. [Artifact receipts](evidence/premium-v2-artifact-receipts-2026-11-18.json)
record downloaded checksums, SDK metadata and installed runtime results. Local commits have identical trees but different author/timestamp
SHAs because this workspace published through GitHub's API after git credential
fetch became unavailable. The manifest explicitly distinguishes them. GitHub
Actions may record a synthetic PR merge SHA rather than the source SHA.

| PR | Scope | Published source SHA |
| --- | --- | --- |
| [54](https://github.com/chandra0000/ludo-lovers-rebuild/pull/54) | Reconcile main and repair emulator shell | a8edd17362f1448b5460d990a89d5d71e5cabe95 |
| [55](https://github.com/chandra0000/ludo-lovers-rebuild/pull/55) | Match orchestration/presentation extraction | 23bcf306328dd7148440ab4edeaefc3063992fb1 |
| [56](https://github.com/chandra0000/ludo-lovers-rebuild/pull/56) | Independent responsive premium HUD | 8a066d95fd3fc2815e18a765def32147d61c9cb2 |
| [57](https://github.com/chandra0000/ludo-lovers-rebuild/pull/57) | Sculpted glass pawns and die settling | 8117b6720d94fcab5403d20e31996529c5007faa |
| [58](https://github.com/chandra0000/ludo-lovers-rebuild/pull/58) | Registry, true 2/3/4-seat Classic, v4 saves | 4faf005557c028a8301efb2993704445c833c1d7 |
| [59](https://github.com/chandra0000/ludo-lovers-rebuild/pull/59) | Approved Quick objective and simulations | a31fd2922e8a9e4418858a639922a2cd5023b7cd |
| [60](https://github.com/chandra0000/ludo-lovers-rebuild/pull/60) | Team Up domain and legacy behavior migration | a78be1e3afe80059bdd51cd8aa0f014b3cffedc0 |
| [61](https://github.com/chandra0000/ludo-lovers-rebuild/pull/61) | Team progress, transfers, result/rematch | f0f46bfb1f3bbf8033c08d2e7a6b1e8b915663a3 |
| [62](https://github.com/chandra0000/ludo-lovers-rebuild/pull/62) | Seeded team-aware AI | 842068272116575716718f60a688ad0d359b35dd |
| [63](https://github.com/chandra0000/ludo-lovers-rebuild/pull/63) | Installed navigation, 29 captures, Home resume refresh | 2822cb969e8906f4c3b7ed093906dc0764badb6d |
| [64](https://github.com/chandra0000/ludo-lovers-rebuild/pull/64) | Online architecture review only | 608a92eb017760041826667de18f480a118e0e97 |
| [65](https://github.com/chandra0000/ludo-lovers-rebuild/pull/65) | Validation-only AAB compilation gate | b732a6189779613d019ee791a660ce8c82516dbd |

Manual merge order is **#54 → #55 → #56 → #57 → #58 → #59 → #60 → #61 →
#62 → #63 → #64 → #65 → evidence documentation**. After each approved predecessor
merges into main, retarget the next PR to main and verify ancestry/checks. Do not
merge a child into an already-merged parent branch; that caused the original
integration gap. Owner review and explicit merge authorization remain required.

## Root causes and preserved contracts

- #43 responsive hangs came from filesystem/encoding work inside widget fake async.
  Full capture I/O now uses real async, bounded waits, asset readiness and disposal;
  tests remain enabled. Four required and six extended responsive fixtures pass.
- Main had only #43 app code despite later PRs being marked merged into stacked
  parent branches. #54 retains both histories/main-only docs and reconciles source.
- The emulator checkpoint failed before Flutter because `/bin/sh` rejected Bash
  `pipefail`; explicit Bash and bounded adb diagnostics fixed it. #54's real
  emulator navigation succeeded; cancellation was never counted as success.
- Color instability was Blue/Magenta HUD/portrait-ring mapping, not engine turn
  order. Restored approved identity fixes and V2 profiles keep permanent seat
  colors; only gold turn indication changes. Names remain metadata, not IDs.
- Home did not refresh a new mode's saved-match card after returning from selection;
  #63 adds the same reload used by the existing setup route, with end-to-end test.
- Team AI treated teammates as enemies and ignored typed team captures; #62 fixes
  scoring using accepted domain events, without modifying dice or movement rules.

MatchSession remains authoritative; immutable snapshots, expectedVersion, command
IDs, duplicate/stale handling, seeded AI and typed events remain outside Flutter.
MatchScreen is reduced through a coordinator, animation/persistence lifecycle
components and read-only board/HUD/result layers. No alternate UI rules engine.
The default `ludo-lovers-current@1` profile is unchanged. Classic, Quick and Team Up
have separate versioned profiles/configurations. No whole-app Flame migration.

Canonical assets unchanged (SHA-256):

- Board: `f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`.
- Live brand icon: `ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793`.

The approved source/extraction registration, 52 track cells, 20 lane cells, 16
sockets, finish and diagonal transitions remain unchanged. A square visible stage
contains the complete existing extraction while one uniform reference transform
positions all board overlays. Pawn geometry was not moved to compensate for HUD.
Existing stars remain in artwork; duplicate overlays are absent, and semantic
safe-cell anchors derive from geometry. Profile/die/social regions are independent.

## Current legacy parity and mode acceptance

The [historical detailed legacy inventory](premium-gameplay-program-2026-11-16.md#verified-legacy-feature-inventory)
records actual legacy paths, compatibility and coverage. Its old rebuild statuses
are superseded by this table and the [execution ledger](premium-v2-program.md).
Legacy source presence is not a claim that legacy tests ran here.

| Feature | Verified legacy finding | Current rebuild classification / decision |
| --- | --- | --- |
| Local compatibility | Real path engine/factory | Fully implemented and tested; preserved shared MatchSession |
| Classic / 2–4 seats | Factory supports selected seats | Fully implemented and tested technically; public acceptance pending |
| Quick | No executable mode found | Fully implemented and tested technically; explicitly approved two-finish rules |
| Team Up | Real priority/departure/transfer rules and tests | Fully implemented and tested technically; migrated into shared pure policy and live HUD |
| Tournament | No executable bracket/progression found | Documented only; blocked after online and product-policy approval |
| Easy/Medium/Hard AI | No verified difficulty selector | Fully implemented and tested; seeded legal choices and Team cooperation |
| Private rooms / online Classic | No working service found | Missing runtime; RFC ready for review, no misleading availability |
| Friends / privacy / moderation | No verified service found | Documented only; dependent on identity/backend/safety design |
| Love Mode | Vision/cosmetics, no executable mode verified | Documented only; intentionally unavailable pending scope |
| Local reactions/chat | Local reaction dock; online-unavailable notice | Fully implemented and tested local UI; no online-service claim |
| Names / square avatars | No editable-name UI found | Fully implemented and tested; Unicode/20-grapheme validation, stable IDs, saves/rematch |
| Restart / rematch / exit | Local reset; no verified exit confirmation | Fully implemented and tested; confirmation, save feedback, cancelled AI/animations |
| Preferences / sound / haptics / motion | Hardcoded feedback; no general settings | Fully implemented and tested local controls with platform-safe fallbacks |
| Match statistics/history | No durable history found | Deferred intentionally; stable result/deduplication policy needed |
| Onboarding | Screen exists, root bypasses it | Fully implemented and tested live first-launch flow |
| Accessibility | Some semantics/hit tests | Partially implemented: semantics, 48dp controls, stack chooser, enlarged text; device audit open |
| Save/resume | Dependency present, no durable save use verified | Fully implemented and tested codecs/controller; physical process-kill/soak remains open |
| Rendering performance | No comparable physical measurement verified | Deferred intentionally; Flutter retained, comparative hardware gate incomplete |

Classic fixed seats are Orange/Magenta for two and Orange/Green/Magenta for three.
Quick starts four yard pawns and ends when any two finish. Team A Orange/Magenta,
Team B Green/Blue; all eight must finish. Team priorities persist immutably;
protected departures, equal arrivals, >2 occupants, turn/bonus transfers and final
finisher are covered. Friendly departure losses do not grant mover capture bonus,
per the explicit approved correction to legacy behavior.

## Test, visual and build evidence

Pinned Flutter 3.35.7 / Dart 3.9.2. Latest local full suite: **414 tests passed**;
strict format across 169 Dart files and fatal-info analysis clean. Eight flow
capture cases re-ran after using the live app theme. YAML parsed, shell scripts
syntax checked, all 29 mandatory PNGs independently decoded/verified. No failing
test was disabled and no timeout was increased as a root-cause substitute.

Dedicated regressions cover deterministic full games, legal moves, releases,
captures/safe cells, stacks/blockades, exact finish, bonuses/third six, restart,
rematch, AI legality and all difficulty/mode combinations, v1–v4 migration,
configuration/profile isolation, duplicate/stale commands, pause/resume, rapid
taps, interrupted animations, exit cancellation, Team stack/turn rules and victory.
Team domain adds 21 scenarios; team UI/recovery adds seven, captures seven; AI adds
18 tests. Compatibility/Classic/Quick suites remain active.

Required viewport captures: 320×640, 360×800, 393×873 and 430×932. Extended cases
exercise compact phones, notch/gesture safe areas, varied DPR and tablet portrait.
Twelve extra live-flow captures and seven Team captures are required alongside ten
responsive PNGs. Linux artifact **14391132410** downloaded; ZIP SHA256
`96c40c6e4b02512b40f07ca89ac3c8cd5d2dd61aa8c42333248e2e74b8f686a4` matches
GitHub's digest. All 29 PNGs verified; compact Team Up inspected from the CI ZIP.
Local 320×640 Team, 393×873 transfer/victory, Classic setup and rolling were also
inspected; downloaded CI 360×800 and 430×932 mandatory captures were inspected too. These are real Flutter widget renders, not physical-device images or
owner-approved designs. SDK-only fonts lack some platform fallback glyphs.

| Evidence | Status |
| --- | --- |
| #54–#62 required CI/build jobs | VERIFIED COMPLETE; exact URLs in manifest |
| #63 foundation/full suite, Android debug/profile/release builds | VERIFIED COMPLETE |
| #63 Android emulator installed navigation | VERIFIED COMPLETE — both installed integration tests passed (43 seconds) |
| #63 iOS simulator compile and installed navigation | VERIFIED COMPLETE — both installed integration tests passed (53 seconds) |
| Native physical Android/iOS, process-kill/soak/memory pressure | BLOCKED — hardware unavailable |
| Final owner screenshot/design acceptance | BLOCKED — owner sign-off required |
| Production signing, Play/App Store acceptance | BLOCKED — credentials/native release review required |

Downloaded current Android debug artifact **14391845174**: ZIP SHA256
`0368d23f1a4a7de49d4e5fcb2465cd9d0c60193c683bde0d267becc5097f4e40`;
APK SHA256 `86e5a94732423d17430c86a9d4ec3a06329c5d91b44b4951b9676971a0c0a3f4`.
Signature verification succeeds with Android Debug certificate; package
`com.ludolovers.ludo_lovers`, minSdk24, compile/targetSdk36. This is not production
signing. Generated native runner label remains `ludo_lovers`; launcher/store/native
configuration needs release review. Native projects are still generated by the
pinned Flutter CI recipe, not committed release configurations. #65 adds release
AAB compilation with explicitly validation-only, nonproduction-signed artifacts;
its actual bundle gate passed [foundation run 44223326622](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44223326622). See [bundle limitations](android-bundle-validation.md).

macOS widget screenshot artifact **14391635476** downloaded: ZIP SHA256
`a122936ad2e6791ab4fb230e40811899030bb62948c5d1af864c71e871d57921` matches digest;
all 29 required PNGs verified and the winning state visually inspected. These
remain macOS widget screenshots, not installed simulator screenshots.

iOS simulator job **134525609912** built the app, booted an iPhone 16 Pro / iOS18.5 simulator (Xcode16.4)
and executed both installed tests; log ends `00:53 +2: All tests passed!`. This
validates simulator interaction, not a real iPhone.

Simulator artifact **14391617229** downloaded: ZIP SHA256
`806efbf31529d856a828308b86cf374a4a8c1b6540b99c2b654b08a02181f141` matches digest.
Info.plist: bundle `com.ludolovers.ludoLovers`, `iphonesimulator`, minimum iOS13.0.

Android emulator job **134525776535** executed both installed tests successfully:
three compatibility navigation cycles and Classic/Quick/Team start/roll/restart/
exit/resume. Log ends `00:43 +2: All tests passed!` on the synthetic PR merge.

Validation-only AAB artifact **14391189823**, source #65
`b732a6189779613d019ee791a660ce8c82516dbd`: downloaded ZIP digest matches
`ef5fbdabd37b4ba6d54632f6fd88ae302fe6553868777b829cf66ea8acb8da53`.
AAB SHA256 `7278959bb12e929ee439624db8107f516138d17273688f1ea7b56ea57c18af20`;
BundleConfig, base manifest and native libraries verified. Embedded JAR certificate
subject is Android Debug, confirmed using OpenSSL; full JAR-signature integrity
verification was not executed. All #65 required jobs passed. No production key or
store validation is claimed.

Successful #63 workflows:
[foundation and profile/release](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44221919359),
[Android debug / iOS simulator runtime](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44221919424),
[Android emulator runtime](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44221969152).
A build or cancelled run does not prove installed gameplay acceptance.

## Accessibility and measured performance

Automated evidence: names above square avatars, stable textual seat/AI indicators,
48dp major controls, engine-legal adjacent/stacked pawn chooser, accessible labels,
150% text, safe-area and overflow checks, reduced-motion settings and interrupted
animation recovery. Remaining acceptance: TalkBack/VoiceOver traversal on devices,
complete contrast audit, magnification and long translated names on native
font stacks. [Selected source text-color contrast calculations](evidence/premium-v2-selected-text-contrast-2026-11-18.json)
verify white names, all four colored seat/AI labels against the brightest profile
gradient endpoint and gold control text against the dark HUD surface exceed 4.5:1.
These analytical source pairs do not verify every pixel, overlay or native font.
No WCAG conformance claim is made from widget checks alone.

[Raw current CI host engine diagnostic](evidence/premium-v2-ci-host-engine-2026-11-18.json):
Dart VM JIT, Linux 4-core GitHub runner, 200 warmups, 20×100 operations per case;
PR synthetic merge source `2887ef09f80cd4d29589fa9334a3a5b1ee31a3e5`. AI decision
median/p95 12.29/13.56 microseconds; snapshot decode 16.265/22.74 microseconds.
Artifact 14391386458 ZIP digest matches
`74a7616c6e2613881d1933d0a69a88ce6db9fce822bc27d877357bc2babd7fba`.
These are host CPU diagnostics only, not profile-device frame times or budgets.

The [Quick simulation samples](evidence/quick-classic-roll-counts-2026-11-17.json)
contain 600 completed matches, no caps, median Classic→Quick rolls 175→98 (2),
326→180 (3), 539→255 (4). Human match duration is not inferred from roll counts.
PR #39 supplies an experiment, not comparable Flutter/Flame device evidence.
Frame build/raster p50/p95/p99, jank, RAM, startup/decode, battery and 16-pawn
animation on representative physical devices remain **BLOCKED**. Production keeps
Flutter; no evidence supports a Flame speed claim. Existing benchmark protocol
and profile APK artifacts are starting points for that hardware run.

## Evidence-based provisional scores

These are engineering-review judgments, not product-owner acceptance or measured
speed scores. A completed coding task alone does not earn 9/10.

| Category | /10 | Evidence and limiting gate |
| --- | --- | --- |
| Architecture | 8 | Pure engine boundaries/coordinator; native project pinning and network extraction pending |
| Gameplay engine | 8.5 | Immutable commands/events, profiles, full simulations; new team complexity still needs soak |
| Gameplay correctness | 8 | Dedicated deterministic regressions; physical lifecycle acceptance incomplete |
| Game modes | 7 | Four local profiles technically tested; previews gated, online/tournament unavailable |
| UI/UX | 7.5 | Real responsive captures, names/control hierarchy; owner feedback and tall-layout polish open |
| Board rendering | 8.5 | Original asset hashes/anchors/entire extraction preserved; source approval #41 historical gate |
| Animations | 7.5 | Finite authoritative dice/movement, reduced motion; device jank/capture polish open |
| Accessibility | 7 | Automated semantics/targets/text; native assistive-tech/contrast acceptance open |
| Performance acceptance | 4 | Real host diagnostics; physical GPU/RAM/frame evidence unavailable |
| CI/CD | 8 | Full static/test/build/artifact gates; installed iOS/Android checkpoints passed |
| Android readiness | 7.5 | Debug/profile/release artifacts; physical/signing/store/soak gates open |
| iOS readiness | 6.5 | Simulator build evidence; runtime smoke passed, no physical/signing evidence |
| Overall production readiness | 6 | Mandatory external acceptance/release gates remain open: NO-GO |

Provisional overall engineering quality: **8/10**. Provisional visual quality:
**7.5/10**. Neither is the requested 9/10 acceptance target.

## Deliverable statuses and remaining order

| Deliverable | Status | Next requirement |
| --- | --- | --- |
| Repository audit, roots, dependency graph | VERIFIED COMPLETE | Recheck ancestry when owner merges |
| Legacy parity inventory | VERIFIED COMPLETE | Runtime acceptance distinct from source inventory |
| Player identity/names/preferences | VERIFIED COMPLETE (automated) | Native accessibility/owner visual acceptance |
| Refactor/HUD/pawns/gold dice | VERIFIED COMPLETE (automated) | Owner visual and hardware performance gates |
| Geometry/safe-star preservation | VERIFIED COMPLETE (automated) | Historical source/derivative approval tracked separately |
| Responsive screenshots | VERIFIED COMPLETE (capture/inspection) | Owner visual sign-off |
| Classic/Quick/Team engine and live UI | VERIFIED COMPLETE (automated) | Keep previews gated until mode acceptance |
| AI and gameplay regressions | VERIFIED COMPLETE (automated) | Device soak/performance |
| Android APK/AAB compilation | VERIFIED COMPLETE | AAB is validation-only; physical devices and production signing remain blocked |
| iOS simulator build/runtime expansion | VERIFIED COMPLETE | Physical-device acceptance remains separate |
| Flutter-versus-Flame physical benchmark | BLOCKED | Comparable physical hardware runs |
| Physical-device acceptance | BLOCKED | Actual Android/iOS devices and recorded results |
| GitHub and Notion engineering docs | VERIFIED COMPLETE | Published source ledger/report; project hub updated, no historical decisions erased |
| Online architecture artifact | IMPLEMENTED, AWAITING VERIFICATION | Review/accept RFC #64 |
| Private rooms/online Classic runtime | BLOCKED | Approved architecture/policies and development services |
| Tournament | BLOCKED | Reliable online plus approved format/eligibility/tie/disconnect policies |
| Love/social expansion | BLOCKED | Approved scope/privacy/moderation and identity backend |
| Release signing/store validation | BLOCKED | Native release config, credentials and owner acceptance |
| Final 9/10 visual/engineering approval | BLOCKED | Acceptance evidence above |

After local PR reviews, prioritize physical compact/
midrange/large Android and iPhone runs, process-kill/resume/long-match soak and
profile-device traces. Review RFC #64 and supply scoped development services only
after its architecture/policies are accepted. Tournament/Love implementation must
not invent unresolved rules or imply an online service. This report does not
approve any merge, deployment, asset change or production release.
