# Royal unified gameplay — release evaluation

Checkpoint: 2026-11-19 (continuing the 2026-11-18 program). **Production verdict: NO-GO.** This is a reviewable local
implementation, not permission to merge, ship or promote preview modes. Native
captures, software renders, physical testing and owner acceptance are distinct.

## Baseline and dependency resolution

Remote main verified at `879f2b555c50575c5db066e0ac8bf530271a965a`. The reviewed
Premium V2 implementation is still in unmerged #54–#66; this program follows #66
rather than discarding fixes or automatically merging them. Legacy main remains
`ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`, verified through GitHub API.
Fresh local baseline: 414 tests passed. Historical main integration/CI failure
causes and the verified legacy matrix remain in the Premium V2 evidence report.

[Exact source/tree/file manifest](evidence/royal-source-manifest-2026-11-18.json)
records each published commit, its identical local tree, every changed file and
workflow URLs. Local commits have different author/timestamp SHAs because API
publishing was used after git remote access failed; do not confuse them with the
published source SHAs. CI can record a synthetic PR merge SHA instead of its head.

| PR | Source SHA | Scope |
| --- | --- | --- |
| [67](https://github.com/chandra0000/ludo-lovers-rebuild/pull/67) | f051cc485edf3c86df598b095ebe24be5ba2e5e7 | One live scaffold, fixed visual slots, centered die/logo |
| [68](https://github.com/chandra0000/ludo-lovers-rebuild/pull/68) | be61c23451a0079250a5a862f0c84a2e21a14e4e | Royal background, crown/header, bounded gold lighting |
| [69](https://github.com/chandra0000/ludo-lovers-rebuild/pull/69) | 5bfe64f41be61984bb2e108a03ea915694da1c7b | Per-profile local social controls and lifecycle |
| [70](https://github.com/chandra0000/ludo-lovers-rebuild/pull/70) | f70b9714722bbbc184f1bbbbe352257dff0a875d | FFA/1v1/computer/Team setup presets |
| [71](https://github.com/chandra0000/ludo-lovers-rebuild/pull/71) | 903f54377613602f6038ffe56949a0cb89b6c059 | AI cleanup, board pixels, captures and native QA gates |

Recommended manual order: existing **#54 → … → #66 → #67 → #68 → #69 → #70 →
#71 → [#72 evidence documentation](https://github.com/chandra0000/ludo-lovers-rebuild/pull/72)**. After each approved predecessor reaches main,
retarget the next PR to main and verify ancestry/checks. Merging a child into an
already-merged parent branch does not promote that child to main. No automatic
merge or force push was performed.

## Phase-by-phase implementation and verification

| Phase | Implemented | Verified / known failure resolution | Status |
| --- | --- | --- | --- |
| 0 audit | Main/legacy/PR/CI/architecture/asset/mode reconciliation | Fresh 414-test baseline; prior required CI green | VERIFIED COMPLETE |
| 1 scaffold | GameBoardScaffold, PlayerSlotResolver, PlayerProfileCard, centered die/logo | 420 tests, required/extended viewports, exact board canvas pixels; obsolete title/component assertions updated to new live contract | VERIFIED COMPLETE (automated) |
| 2 royal presentation | Full RoyalBackdrop, crown/header, glass frames, stable accents, team badges | 422 tests, cached/no-idle-frame/pointer checks; source logo preserved | VERIFIED COMPLETE (automated) |
| 3 dice/pawns | Reused sculpted glass pawns, authoritative gold cube, cell movement/landing/capture/finish; new bounded arena lighting | Existing die six-face/duplicate/interruption and pawn/geometry/stack suites retained | VERIFIED COMPLETE (automated) |
| 4 social | Eight per-profile controls, presets, local emoji and avatar bubbles; shared emoji removed | 430 tests; fixed 10–12px compact control overflow without shrinking 48dp targets; sender/expiry/disposal/enlarged-text checks | VERIFIED COMPLETE (automated) |
| 5 local configurations | FFA, true 1v1, configured AI and Team-Up presets over shared registry | 435 tests, real saved participant/bot counts, profile isolation and public gates; Quick remains separate | VERIFIED COMPLETE (automated) |
| 6 hardening | Actual AI timer cancellation, crown constraint, emoji fallback, 36 software captures and installed screenshot driver | 445 local tests; new AI teardown regression first failed on 450ms orphan timer and now passes; composited board pixels protected | VERIFIED COMPLETE (automated) — final CI/native captures passed |

The final full suite passes **445 tests** in 137 seconds; the clean-pointer
follow-up changes only integration capture framing and passes all 445 again in CI. Strict formatting of all
188 Dart files using `dart format --output=none --set-exit-if-changed .` and
`flutter analyze --fatal-infos` pass. Workflow YAML and shell scripts parse. No
failing test was disabled, timeout increased to hide a failure, or cancelled run
counted as success. Integration fixtures keep three-minute per-test bounds,
bounded image readiness and 15-second screenshot transactions.

### Authoritative architecture and preserved assets

MatchSession and immutable LudoGame remain authoritative. There is **no change to
pure game domain/application code, default/alternate rule profiles, geometry or
assets** relative to #66. UI state dispatches existing commands; dice renders the
accepted result, not an independent random face. FFA/computer retain compatibility
rules; 1v1 derives seats from approved Classic configuration; Team-Up preserves
priority/departure/transfer rules, final finisher and eight-pawn team victory.

Visual slots are Orange top-left, Green top-right, Blue bottom-left, Magenta
bottom-right. Engine scheduling remains Orange → Green → Magenta → Blue with
mode-authoritative skipping/transfers. Profile names/IDs, bot roles, team identity
and progress come from configuration/state; names never become authoritative IDs.
Names keep the existing Unicode/20-grapheme validation and persistence behavior.

The complete existing artwork extraction remains registered through one uniform
576×1024 reference transform. Square board stage, all 52 track cells, 20 home-lane
positions, 16 yard sockets, finish, diagonal transitions and safe stars are intact.
There is no newly generated/cropped/rotated board. Pixel tests protect both the
old/new reference-canvas pixels and the composited board when a bottom profile
gains gold glow. Profile/social/die effects are bounded to independent HUD regions.
`BoardGeometry.visualApprovalPending` remains true; no readiness flag is promoted.

SHA-256 unchanged:

- Board: `f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`.
- Live approved logo: `ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793`.
- Brand accents remain Orange #FF8928, Green #33FF28, Blue #289EFF, Magenta #F428FF.

RoyalBackdrop uses static deterministic gradients, radial lighting, low-opacity
bokeh, corner paths and vignette; it adds no particle loop/fullscreen blur. Its
RepaintBoundary and immutable painter isolate background repainting. Crown and die
lighting are bounded and do not modify rule timing. The old layout is retained only
as an isolated regression reference, not another playable screen.

### Diagnosed and fixed defects

- Compact social cards overflowed by 10–12px because two 48dp controls exceeded
  padding/border-adjusted height. Explicit space and compact identity layout fix it;
  controls stay at least 48×48, icons 28dp, square avatars 40dp.
- Header crown inherited the logo's 72dp width. Centered loose constraints restore
  a 16dp square; a regression reproduces the stretched width and protects the fix.
- AI generation cancellation rejected stale callbacks but left Future.delayed's
  450ms timer pending after disposal. The same scheduler now owns/cancels a Timer,
  preserving delay/generation/commands. No artificial test flush masks the defect.
- SDK-only fonts produced emoji tofu in software captures. Explicit platform font
  fallback and optional installed Noto emoji face in test setup render real glyphs;
  no runtime artwork/font asset is replaced. Native screenshots use native fonts.
- The original calibration option to hide profiles is still honored and tested.

## Mode and legacy parity

The [verified legacy inventory](premium-gameplay-program-2026-11-16.md#verified-legacy-feature-inventory)
and [Premium V2 matrix](premium-v2-release-readiness-2026-11-18.md#current-legacy-parity-and-mode-acceptance)
remain the detailed behavioral record; legacy tests were not re-executed here.
This royal increment integrates existing accepted features, not another migration
of the same engine. Four local presentation configurations use one screen:

| Configuration | Participants / presentation | Availability |
| --- | --- | --- |
| Four-player FFA | Four configured humans; no team badges | Current local compatibility availability retained |
| Two-player 1v1 | Approved two-seat Classic roster; absent slots EMPTY/WAITING | Internal preview pending mode/owner acceptance |
| VS Computer | Configured human/bot seats; robots, BOT·AI and actual thinking state | Existing local AI available; preset keeps at least one bot |
| Team-Up 2v2 | Domain team assignments, progress/capacity, transferred turns/results | Internal preview pending mode/owner acceptance |
| Quick | Existing separate approved two-finish profile/configuration | Internal preview retained |
| Rooms / online / friends / coins | No working legacy service verified | Not implemented; no misleading availability |
| Tournament / Love | No approved complete executable specification/service | Deferred behind specifications and required backend gates |

Local chat/reactions are explicitly on-device. Per-profile callbacks capture the
originating seat and never send a network message or invent an AI response.
SocialOverlayCoordinator bounds one two-second bubble/timer per seat, replaces
repeated input, expires feedback and clears on rematch/dispose. Bubbles remain
inside avatar cards and have reduced-motion/live semantics. The local sheet has
presets and intentional scrolling under compact/text/keyboard constraints.

## Screenshots, CI and artifacts

**Software screenshots — VERIFIED COMPLETE:** all 36 required PNGs generate and
decode. Required sizes 320×640, 360×800, 393×873, 430×932 plus compact/notch/DPR/
tablet cases. Existing Home, mode selection, setup, dice, movement, capture,
victory/rematch captures remain; seven royal captures add FFA, 1v1, computer,
Team-Up, emoji picker, local bubble and chat. Tests reuse the production theme.

Linux artifact **14395577238** downloaded and all 36 required PNGs verified. ZIP
SHA256 `99b34e108e039cdd4e3d9475ceac7c769a87a4a591a3f5f9185665f8ccf68366`
matches GitHub digest. Compact social layout, 393×873 1v1/computer/Team and social
captures inspected; downloaded CI emoji picker inspected with proper glyphs.
Final-source software artifact **14498133271** also downloaded: ZIP SHA256
`21eefb1754cb6ccecc153a5c08c87daf2ea4686489d16f57178f4f974d16abef`
matched; all 36 required PNGs verified. Pillow fully decoded all 37 PNGs in
that archive (36 required plus the extra canvas) and all eight clean Android PNGs.
All 37 final software images also match the initial source672 archive exactly
in dimensions and complete RGBA byte arrays; the CI-launch fixes introduced no
software-rendered pixel changes.
The 320×640 match and 393×873 emoji picker
were inspected, confirming compact composition and real emoji glyphs. These are
actual Flutter renders, not concept art or owner visual sign-off.

**Native installed captures — Android and iOS VERIFIED COMPLETE:** new extended
integration driver requires eight PNGs separately on Android emulator and iPhone
simulator (FFA, Classic, Quick, Team-Up, computer, picker, bubble, chat). Host writes
validate signature and full PNG decoder/CRC checks reject missing/corrupt captures.
Android SDK image-surface conversion is automatically reverted per-test; this
capture path intentionally affects rendering and is not a performance trace.
The original source `6722614c69808f4bea8dacb25039082272feac88` passed both platforms:
Android app log ended `00:51 +4: All tests passed!`; iPhone simulator log ended
`00:59 +4: All tests passed!`. Three named integration scenarios completed on each
platform, plus framework teardown. All eight PNGs per platform verified. Inspection
found a synthetic LiveTestWidgetsFlutterBinding pointer crosshair in Android
captures. Follow-up `b6d031f6797294ab5e5726f9732a844220fbf2e4` changes only the native
fixture: three bounded paint frames drain its two-frame pointer fade, with no image
postprocessing. Clean Android run 44233862303 passed all three scenarios; log ends
`00:48 +4: All tests passed!`. Artifact **14397245639** downloaded, all eight PNGs
validated at 1080×1857, and Team-Up inspected without the synthetic crosshair.
ZIP SHA256 `38b043441cd0c7e951a369795000ae62e479b6d9d993e59be040fda1993124a5`
matches digest. These are installed Flutter-view captures, not physical-device
or OS-chrome screenshots. The follow-up iOS run 44233763881 failed its existing 15-minute native-step
bound after Xcode completed. Diagnostics show a booted simulator and no Runner
output; the logs narrow the stall to post-build deployment/VM-service attachment,
but do not prove which implicit Flutter substep failed. It is not counted as green.

Source `53953bcb70775d34ca67383a96b321d61a4f3e33` replaces that opaque launch
path with an isolated simulator and separately bounded build, install, console
launch, loopback VM-service discovery and driver attachment. Console logs and
selected runtime are retained. No test is disabled or outer timeout increased.
The normal AppMain simulator build is now uploaded before the integration target
overwrites Runner.app; those two bundles must not be confused. Local Python
syntax/URI-parser fixtures, Bash syntax and workflow parsing pass; actual macOS
execution remains a CI gate. Run 44455344463 passed boot/build/install and launched Runner, then failed the
60-second VM-service discovery bound. Its preserved console contains the app PID
but no Flutter VM-service line. Pinned Flutter SDK source (`ios/simulators.dart`,
`launchDeviceUnifiedLogging`) shows that modern iOS emits the engine message through
Apple's unified log, which the new launcher had omitted. Follow-up source
`36817b0c1db94ba4f12cf2eb0fe9a3c5d312aba2` starts and preserves that stream before
launch and discovers the service from either channel. Four local URI fixtures
(including a native-style line and rejection of non-loopback URLs) pass. Bounds,
required scenarios and captures are unchanged.

That unified-log run 44456771700 still failed host discovery, but artifact
14498422068 proves Runner executed all three scenarios: `00:55 +4: All tests
passed!`. No VM-service announcement was captured and the screenshot driver never
attached, so this is **not** successful native capture acceptance. The exact reason
the one-shot engine announcement is absent is not proven. Source
`903f54377613602f6038ffe56949a0cb89b6c059` removes that dependency: it reserves an
ephemeral loopback port, launches this isolated CI simulator with explicit service
port/publication/auth flags, polls `getVM` for a typed VM response within the same
60-second bound, then attaches the unchanged driver. Auth relaxation is scoped to
the isolated simulator debug process, not a production build or physical device.
Unified console/logs remain diagnostic. A real local Dart VM successfully exercised
the HTTP readiness check; connection refusal is rejected. The standalone Dart CLI
rejected the iOS-only publication flag in the first local test command; removing
that embedder-only flag from the local test allowed the protocol check to pass.
Final run **44458139058**, job **135338502738**, passed every stage: boot,
build, install, loopback readiness, driver attach, scenarios, PNG verification and
cleanup. Driver log reports `All tests passed.` Eight PNGs at 1206×2622 were
required. Artifact **14498419118** downloaded; ZIP SHA256
`f0b0ca4ce30df0ffb7545cd9883536b3f129762613271124aa7c0859275bb1e7`
matched, all eight CRC/inflate checks and full Pillow pixel decodes passed.
Team-Up and emoji picker were visually inspected: no synthetic pointer crosshair,
correct quadrant identities, native emoji glyphs and complete board. Runtime:
iPhone16Pro/iOS18.5/Xcode16.4. These are installed Flutter-view captures, not
OS-chrome or physical-device screenshots and not owner visual acceptance.

**Both current workflows are successful.** The dedicated readiness protocol fixes
the demonstrated host discovery failure without increasing bounds or changing app
tests/rules. The earlier opaque failure's exact hidden substep remains unproven;
subsequent staged logs establish that healthy app tests could run while host
startup-announcement discovery stalled.

Earlier clean-pointer source workflows (iOS failed):

- [Foundation/full tests/profile/release/AAB](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44233763765).
- [Android debug/iOS installed simulator](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44233763881).
- [Android installed emulator checkpoint](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44233862303).

#67–#70 required CI passed, including installed iOS navigation. The original final-source
full gates passed; the clean-pointer source also passed all 445 CI tests and Android
builds. Its clean Android capture job also passed; its iOS job failed as described above.
Current loopback-readiness workflows are [foundation](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44458139120)
and [cross-platform](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44458139058).
Foundation runs 44455344433 and 44456771757 passed all 445 tests and
profile/release/AAB builds.
The repair changes only iOS launch scripts and workflow order; application/Dart
fixture code is identical to the verified clean Android source. Profile APKs now
include internal modes for concrete owner/device review, clearly named
`ludo-internal-modes-profile-apks`. Release APK/AAB/default debug builds retain
normal public gates. Earlier clean-source internal profile artifact **14396657022** downloaded: ZIP SHA256
`1b6fafd1001f2265513cb7c7cbe3b9b41ddaa36080314017a4ee6afb0dc33723` matches digest.
ARM64 profile APK SHA256
`dec6e8fd6be7f6976ca02406c2e1e6a40d6bfce0bc5689b19f70fb8bfe6762a3`;
APK signature verifies with Android Debug certificate. Initial final-code ARM64
release APK and AAB were independently downloaded and verified for build/package/
structure evidence; their full receipts distinguish that source from the fixture
follow-up. No production signing or full JAR signature acceptance is implied.

Verified internal profile artifact **14498223046** (source36817b0; identical app
code, before the CI-only loopback change) was also downloaded and
its ZIP SHA256 `7a30f827adcd46a9df9ebef96a58dc3191e8fc3507c2bc0aa604240d3e91defb`
verified. ARM64 APK SHA256
`a3db480dfbdcf972969eb25c33c6abe5c25ee165235b114a533cfec4264277c9`.
`apksigner verify --print-certs` passes (Android Debug certificate); package
`com.ludolovers.ludo_lovers`, minimum SDK24, target/compile SDK36. This remains
an internal review/profile artifact, not production signing or physical acceptance.
Latest source903f543 foundation run **44458139120** also passed all 445 tests and
profile/release/AAB builds. Its profile artifact **14498769144**, release APKs
**14499151481** and AAB **14498699412** exist; these latest build archives were not
independently downloaded in this checkpoint. Receipts distinguish CI evidence
from the downloaded/signed APK checks above.

Normal AppMain simulator artifact **14497084656** was downloaded and its ZIP
SHA256 `31dbab3617e0dc02f09df2feb1b8995bd7822de585e8e7724792ca4c8ba6f04c`
matched GitHub's digest. Info.plist identifies `com.ludolovers.ludoLovers`,
minimum iOS13.0 and iPhoneSimulator18.5. This proves the normal simulator bundle
build; installed integration scenarios use a separately built test target.

Generated runners still use debug signing; native app
identity/launcher/configuration, production signing and store acceptance remain
separate release tasks. An AAB build is not Play acceptance.

### Diagnosed dependency-service failure

The first Android debug attempt on run 44456771700 (job 135333584633) failed
before app compilation: Gradle could not resolve Kotlin2.0.21 stdlib/plugin/BOM
POMs from plugins.gradle.org. Direct checks of the exact stdlib/BOM URLs and the
Maven Central stdlib endpoint subsequently returned HTTP200 with valid POM bytes.
The preceding identical application build passed. A targeted retry of only the failed Android job passed
(job 135336992229). The original failure is retained; iOS was not retried blindly. No dependency/rule/test is changed to hide the outage.

## Accessibility and performance limits

Automated checks cover four-corner semantics, stable color/name/AI/team identity,
48dp per-profile and footer controls, square avatars/names above, engine-legal
adjacent/stacked pawn chooser, 150% text, safe areas, no responsive overflow,
reduced motion, timer cancellation and rapid/duplicate input. Full names remain
available semantically when compact cards truncate them. Native TalkBack/VoiceOver,
contrast across every overlay/font, memory pressure and physical touch/soak remain
unexecuted. Do not call this WCAG conformance or physical-device acceptance.

[Raw current CI host engine diagnostic](evidence/royal-host-engine-2026-11-18.json):
Linux four-core GitHub runner, Dart3.9.2 VM/JIT, 200 warmups and 20×100 operations;
synthetic CI merge `96b7d9b2535cdaaa1cb0b767bb04542b50fca9b4`. Seeded AI decision
median/p95 12.025/16.97 microseconds; snapshot decode 15.52/28.51 microseconds.
Artifact **14396335079** ZIP digest
`38202b7637cd11ec9d74a2ee7fa9751ca7b63f3389c37fb1b328c08c1b4dc796` verified.
These are CPU diagnostics, not device frame times or proof of 60fps.

UI/raster p50/p95/p99, dropped frames, GPU/image decode, RAM, battery, startup and
rebuild tracing on representative phones remain **BLOCKED** on hardware. No
Flutter-versus-Flame speed claim is made; Flutter remains production renderer.
Use internal profile APKs and [the physical/paired renderer protocol](../DEVICE_ACCEPTANCE_AND_PERFORMANCE.md).
Typical 6.1–6.9-inch physical-device acceptance cannot be inferred from logical
viewport tests or simulator model names.

## Provisional engineering review

These are evidence-based reviewer judgments, not owner scores or acceptance.

| Category | Target | Provisional result / remaining limit |
| --- | --- | --- |
| UI/UX | 9 | 8 — original royal layout/real captures; owner review and compact-name polish remain |
| Gameplay reliability | 9.5 | 8.5 — deterministic regressions and lifecycle fixes; physical interruption/soak open |
| Board fidelity | 10 | 9.5 — unchanged assets/anchors and exact pixels; physical/owner alignment gate open |
| Dice/pawn animation | 9 | 8 — accepted gold/glass/cell animation reused and bounded; device jank unmeasured |
| Responsive layout | 9 | 8.5 — required/extended cases, safe areas/48dp controls pass; physical touch acceptance open |
| Accessibility | 9 | 8 — semantics/targets/motion/text tested; native assistive technology/complete contrast open |
| Architecture | 9 | 8.5 — shared scaffold/session and bounded controllers; MatchScreen/native release config still deserve review |
| Performance | 9 | NOT SCORED — no representative physical GPU/frame/memory measurements |

Overall production readiness remains **6.5/10, NO-GO** pending the gates below.
No target score is assumed from task completion.

| Deliverable / gate | Status | Remaining action |
| --- | --- | --- |
| Audit, dependency graph, mode/legacy inventory | VERIFIED COMPLETE | Recheck main ancestry when owner merges |
| Unified live scaffold, royal background/cards/dice arena | VERIFIED COMPLETE (automated) | Owner visual acceptance |
| Four local configurations, names, AI/team identity/scoring | VERIFIED COMPLETE (automated) | Preview mode acceptance; no public promotion assumed |
| Per-profile social/presets/cleanup | VERIFIED COMPLETE (automated) | Native/device usability review; remains local-only |
| Engine/geometry/persistence/lifecycle regression | VERIFIED COMPLETE (automated) | Physical long-match/process-kill testing |
| 36 responsive/flow software screenshots | VERIFIED COMPLETE | Owner design approval distinct from inspection |
| Final native screenshot/build/CI gates | VERIFIED COMPLETE | Final workflows green; 8 Android + 8 iOS PNGs validated, downloaded and inspected |
| GitHub/Notion documentation | VERIFIED COMPLETE | Evidence PR #72 and append-only project-hub checkpoints; all PRs unmerged |
| Physical Android/iOS and measured renderer performance | BLOCKED | Actual hardware and traces |
| Production signing/native/store release | BLOCKED | Approved native configuration, keys and distribution acceptance |
| Online/private rooms/tournament/coins/social backend | BLOCKED | Existing RFC/policies/infrastructure gates; outside this local UI delivery |
| Final 9+/10 and production approval | BLOCKED | Owner visuals, device/accessibility/performance/release evidence |

All code PRs remain unmerged. Review the new UI and internal profile APKs, then
perform compact/midrange/large Android and physical iPhone runs with recorded
viewport/DPR/insets, mode/profile/build/source and test outcomes. No merge,
deployment, new asset or production readiness is authorized by this report.


## Requested deliverables index

| Deliverable | Status | Evidence / limit |
| --- | --- | --- |
| 1 repository audit | VERIFIED COMPLETE | Baseline/dependency section and preceding Premium V2 audit |
| 2 feature parity matrix | VERIFIED COMPLETE | Linked verified legacy inventory; no README-only feature treated as working |
| 3 player-color root cause | VERIFIED COMPLETE | Earlier identity report: HUD quadrant/ring mismatch; fixed seat resolver, independent active highlight |
| 4 dynamic names | VERIFIED COMPLETE (automated) | Existing validated Unicode setup, saved roster/resume/results preserved |
| 5 premium pawns | VERIFIED COMPLETE (automated) | Sculpted painter reused; geometry/movement/stack regressions |
| 6 animated gold dice | VERIFIED COMPLETE (automated) | Authoritative die/duplicate/interruption tests; centered tappable arena |
| 7 safe stars and board | VERIFIED COMPLETE (automated) | Geometry semantics, no duplicate stars, unchanged asset and exact pixel tests |
| 8 responsive screenshots | VERIFIED COMPLETE (software) | 36 required PNGs; native status recorded separately above |
| 9 engine/gameplay regressions | VERIFIED COMPLETE (automated) | All 445 tests; profiles and pure domain unchanged in royal increment |
| 10 legacy migration summary | VERIFIED COMPLETE | Existing Quick/Team/AI migration reused; unsupported services remain unavailable |
| 11 performance benchmark | BLOCKED | Raw host CPU diagnostic available; physical Flutter/Flame measurements absent |
| 12 CI workflow links | VERIFIED COMPLETE | Exact run URLs and historical conclusions in source manifest |
| 13 Android/iOS build evidence | VERIFIED COMPLETE | APK/AAB and simulator build/runtime receipts above; physical/store gates separate |
| 14 PRs and source SHAs | VERIFIED COMPLETE | #67–#71 and complete changed-file manifest; unmerged |
| 15 GitHub/Notion docs | VERIFIED COMPLETE | Evidence PR #72 plus append-only Notion hub updates |
| 16 outstanding blockers | VERIFIED COMPLETE | Explicit release gate table; no gate silently waived |
| 17 visual quality score | IMPLEMENTED, AWAITING VERIFICATION | Provisional 8/10 engineering review; owner acceptance absent |
| 18 engineering quality score | IMPLEMENTED, AWAITING VERIFICATION | Provisional 8.5/10 architecture/gameplay review; device limits remain |
| 19 production verdict | VERIFIED COMPLETE | NO-GO, provisional 6.5/10; not production approval |
| 20 merge order | VERIFIED COMPLETE | #54 through #72 in sequence; owner authorization required |

Backend-dependent online Classic/private rooms, tournament and Love/social runtime
are **NOT STARTED** in this royal increment and **BLOCKED** by the documented
architecture/policy/service dependencies. No UI card implies that those services
exist. Physical and visual acceptance require human evidence and cannot be replaced
by another software test run.


Notion project hub: https://app.notion.com/p/3f5d7b2be1cc81fea8f5f4b450a42160.
The final checkpoint preserves historical decisions/failures and records the
new approved corner direction, successful final CI, actual capture receipts and
unchanged physical/performance/signing/owner gates.
