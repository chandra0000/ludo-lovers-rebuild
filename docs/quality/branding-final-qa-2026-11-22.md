# Branding and installed gameplay QA evidence

Scoped Android implementation and recording: **VERIFIED COMPLETE**. Production
release: **BLOCKED**. No owner visual approval or release gate has been cleared.

## Review and source

[PR #76](https://github.com/chandra0000/ludo-lovers-rebuild/pull/76) is isolated on
`feat/branding-typography-gameplay-qa`, based on recording PR #75 rather than older
main. Review after #73 → #74 → #75 and their existing predecessors. None was merged
or force-pushed. Baseline #75: `e6a6fa785a243c0b410e43228445ec6bfb12af5f`;
main at investigation: `879f2b555c50575c5db066e0ac8bf530271a965a`.

Exact recorded application: `85c10f554847ec6529a3894b429f8e96d1b971a4`.
QA-only iOS host follow-ups: `44ab1543b1c9e44f86b8a424dcc5f539c33679c1`
and direct SDK-host attachment `eba8213412cc5c30ffa4d0b6951e7ddf8ef6b92f`.
All have application `lib` tree `c0cd1940cfae301efce61521f33b35f4afadfc0d`.
The later documentation receipt does not change the recorded application.

## Implemented

- Locally bundled/licensed Cinzel700 and Nunito400/600/700/800, semantic theme
  styles and real-font screenshot loading. Exact sizes/colors/fallbacks are in
  [the implementation ledger](branding-typography-gameplay-2026-11-22.md).
  System TextScaler is not capped.
- Reproducible Android legacy/adaptive/monochrome and opaque iOS icons from the
  unchanged approved logo; native launch resources and CI restoration after
  platform scaffolding. Installed label remains Ludo Lovers; identifiers unchanged.
- Initialization-driven royal splash, bounded error/retry, foreground/disposal
  guards, no fixed1800ms delay. Production first-frame ownership occurs before
  runApp and releases after a frame; a scheduler-phase regression verifies it.
- Readable single authoritative gameplay status, full-width names above avatars,
  48dp controls, enlarged-text Team-Up presentation and an accessible pawn sheet.
- Gold dice face joins refined without changing authoritative values; pawn
  under-outline/contact shadow improved without changing shapes or anchors.
- Existing native recorder extended through launcher/cold startup/home/setup,
  actual background/warm return and deterministic gameplay. No footage editing.

Board/logo bytes, BoardGeometry, MatchSession, rules, persistence format, quadrant
identity and Orange → Green → Magenta → Blue turn order remain unchanged. Internal
mode previews remain QA-gated; this does not ship online services or clear modes.

## Actual recording and screenshots

[Download MP4 artifact](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591/artifacts/14751477914)
from [successful recording run45015085591](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591).
ZIP contains `gameplay-android.mp4`, authoritative state/events, runtime diagnostics,
recorder-finalization proof and machine verification. Artifact retention is30days.

MP4 SHA256: `7bf275a42883440d6a4dfcac4ae976502cd41f3bf984be76fa9d3ca02f8cf80d`.
Duration90.681878s; physical capture360×800; H.264 Constrained Baseline/yuv420p;
694 encoded frames. Android13/API33 google_apis x86_64 Pixel2 emulator profile,
emulator37.3.10, overridden density160/DPR1. Flutter3.35.7/Dart3.9.2, debug,
Skia software (`--enable-software-rendering --no-enable-impeller`). This is emulator
evidence, not physical-device or production GPU performance evidence.

Full-stream ffmpeg decode produced zero errors; packet DTS is strictly increasing.
Full-duration sampled storyboards and detailed dice/travel/capture/AI frames were
inspected. Names, icons and status are readable in the installed app, unlike the
old widget-test font substitution. Complete square board and color identity remain
visible. This was decode/storyboard/motion-frame inspection, not a claim of
real-time GUI playback or owner visual approval.

Encoded mean7.65fps includes idle/startup holds; median active cadence22.10fps
uses positive frame intervals ≤150ms. **30fps target is not met.** Do not compare
this as a measured performance improvement over the historical clip. One1.06s
empty royal interval at44.015–45.075s remains during integration-entry/driver
handoff after disclosed APK replacement. It is unedited and not evidence of a
normal cold-start failure. Normal startup is separately captured.

[32 installed-app PNGs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591/artifacts/14752370005)
include genuine launcher icon (native-normal-background.png after first launch),
native cold splash, home/setup, all local preview
modes, chat and emoji. Launcher dock icon identity is confirmed by UI hierarchy
label Ludo Lovers; the dock does not visibly print that label. The earlier
native-installed-launcher.png was taken before the launcher prediction refreshed
and shows Gmail in that slot; it is not the icon-approval image.

[51 real-font Flutter PNGs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050576/artifacts/14751353488)
include320×640,360×800,393×873,430×932 at100%/200%, long/Unicode names,
Team-Up enlarged text, chooser and Victory. Widget PNGs are not native captures.
All83 current PNGs fully decode; required native screenshot verifier passes.

Before launcher/splash PNGs are the actual installed historical APK from
run44875002916, source`bdf08df75fdba52fbea9a889ff43e74e1b62dc58`, captured on the
same recording runner. Its launcher frame does not yet show the app icon, so
there is no valid matched before/after launcher-icon comparison. Current installed
icon evidence comes from the post-launch background frame. Before pawn-menu frame
comes from historical clip SHA256
`405a2c00169043e8bf422e75a25d380f134cfeee25c77e0dd21eb552f33d21c5`.
Historical evidence is never substituted for the current recording.

## Deterministic fixture disclosure

Normal launcher/startup/home/setup uses the normal APK. The subsequent integration
APK uses production widgets/engine/animation timings with test-only mode/recording
flags and mock saved preferences. First fresh match: Aarya/Renée/Maya/Leo, rolls6,3,
yard release then three-cell movement, versions0–4. A disclosed replacement match
stages Orange progress0 and Green progress42/10 for capture. Human rolls3,2,1;
Green medium AI seed17 rolls4 and advances10→14. Capture returns Green pawn0 to
yard and grants Orange's applicable extra turn. Magenta's no-legal-move pass hands
off to Blue, version8. The changed Green bot/name belongs to this new fixture. Debug test touch
markers may appear; they are not release artwork.

Assertions check MatchSession versions, dice, active player, progress/capture and
duplicate input rejection. Video alone is not correctness proof. Native scenarios
also cover edited Unicode names, exit/re-entry, local preview setup/restart and
same-process restoration. These do not prove process-death recovery.

## Verification

Reproduce formatting/analysis/tests from `apps/mobile` with the pinned SDK:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
python3 tool/test_native_branding.py
```

From repository root: `python3 .github/scripts/test_android_native_qa.py`.
For native evidence, run **Android gameplay recording (seeded QA)** on this branch
or use the opt-in `run-gameplay-recording` PR label before the workflow is on main.
The workflow prebuilds both normal and integration APKs, installs the actual app,
records natively and validates the finalized file. Local emulator commands and
fixture details are in [recording instructions](android-gameplay-recording.md).
The branding prelude additionally needs the normal `app-branding-debug.apk` and
the disclosed historical baseline APK; the workflow prepares both.

| Check | Result / scope |
| --- | --- |
| Strict Dart formatting; fatal-info analyzer | PASS,198 Dart files checked |
| Full Flutter unit/widget suite | PASS,471 tests |
| Host recorder protocol / branding checks | PASS,11 +3 tests; Python/YAML/shell checks |
| Responsive real-font/200% screenshots | PASS, four required viewports and enlarged Team-Up |
| Android installed scenarios / recording | PASS, software debug emulator; authoritative assertions |
| Android debug/profile/release/APK/AAB | PASS, validation artifacts, not production signed |
| iOS simulator compilation | PASS, normal and integration apps compile |
| iOS installed runtime | BLOCKED; latest simctl install90s timeout before launch; earlier four assertions passed but host job failed |
| Contrast / semantics | PASS scoped palette and automated labels/targets; full native screen-reader acceptance pending |
| 30fps capture target | FAIL,22.10fps median active cadence |
| Default Android GPU acceptance | FAIL/unresolved runtime loss; software pass cannot clear it |
| Physical Android/iOS, process death, soak | BLOCKED, no physical devices / unexecuted acceptance |
| Owner visual approval / signing / store | BLOCKED, separate acceptance gates |

[Foundation45015050576](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050576)
passes all required jobs for the recorded app, including release/profile builds.
[Release APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050576/artifacts/14751806119),
[profile APKs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050576/artifacts/14751418101),
[validation AAB](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050576/artifacts/14751566751),
[normal debug APK](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591/artifacts/14751383223).

First QA-host checks:
[foundation45016648593](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45016648593),
[cross-platform45016648518](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45016648518).
These must be read by their actual conclusion, never assumed green from builds.

## Confirmed causes and unresolved failures

Confirmed startup regression in an intermediate revision: widget-owned
allowFirstFrame ran during render finalization, triggering Flutter's
debugFrameWasSentToEngine assertion. Red/green scheduler-phase regression led to
StartupFrameGate before runApp with post-frame release. No exception suppressed.

Confirmed old QA blank: explicit200ms empty-widget unmount between fixtures.
Removed; APK replacement is disclosed and returns to launcher. Remaining driver
handoff interval above is not concealed. Dice corner rounding caused visible
plane gaps in sampled motion; smaller bevels retain the same six-face cube/style.

iOS source014bd8cb attached and captured eight PNGs but failed first-test
SemanticsHandle teardown. Source85c10f compiled both apps but simctl launch failed
to acknowledge a PID in30s (run45015050589). QA follow-up moves integration
compilation before simulator boot and preserves partial output/failure screenshot/
service logs without enlarging limits. Neither prior failure is a native pass;
underlying launch/accessibility ownership cause remains unproven.

[Default-renderer45013400655](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013400655)
built, booted and captured FFA, then Flutter driver disappeared, ADB went offline
and QEMU exited. No kernel OOM or native crash signature established the trigger.
Viewport1080×1920 also differs from software360×800, so this is not a controlled
renderer-only comparison. No blind reruns or gameplay changes conceal the failure.

Recommendation: review the scoped implementation and Android evidence; retain
draft/hold status until iOS/runtime and required release acceptance are resolved.
Do not assign target9/10 scores from task completion or declare production-ready.

### iOS result-collection diagnosis

Run45016648518 launched successfully. Unified Runner logs report all four tests
passed at11:27:34, with native semantics active and start/end handle counts1/1.
All eight native PNGs were saved. However flutter drive started at11:26:31 and
its host connected only at11:29:24, exhausting the existing180s window while
requesting results. The job remains FAILED, not green from test log messages.

The QA-only direct-host follow-up invokes the same native_capture_driver.dart
through Dart with VM_SERVICE_URL pointing to the already verified simulator VM,
as Flutter SDK startTest does. This removes redundant Flutter tool attachment setup and
preserves all result assertions, screenshot callbacks and the180s bound. No app
code changes or fresh Android video are needed.

[Retained iOS PNGs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45016648518/artifacts/14751924522)
and [diagnostics](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45016648518/artifacts/14752323203)
are evidence from a failed host job, not completed iOS acceptance.

Current direct-host checks:
[cross-platform45017921725](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45017921725),
[foundation45017921726](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45017921726).

## Documentation and review handoff

The [Notion project hub](https://app.notion.com/p/3f5d7b2be1cc81fea8f5f4b450a42160)
was read and updated with append-only implementation/Android receipts, exact
commits, iOS diagnostics and remaining gates. Historical decisions were retained.
The repository ledger holds the exact typography table and native generation
commands. Current artifacts expire; download them for durable owner acceptance.

### Final bounded iOS outcome

Run45017921725 is FAILED: `xcrun simctl install` exceeded90s before application
launch on iPhone16Pro/iOS18.5. The direct Dart host correction was not reached
and is IMPLEMENTED, AWAITING VERIFICATION. Do not claim its root cause or fix
verified from the earlier passing test messages. No further blind rerun or timeout
increase was made. [Retained failure diagnostics](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45017921725/artifacts/14751814139)
and [unsigned simulator app](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45017921725/artifacts/14752846077)
remain available. Native installation/runtime acceptance is BLOCKED by this
reproduced simulator-tool boundary failure; the underlying trigger is unproven.

Foundation45017921726 is SUCCESS, including formatting, fatal-info analysis,
full unit/widget suite and Android profile/release/APK/AAB jobs. Android debug
job in45017921725 is SUCCESS. Application lib/assets remain identical to the
inspected recording source85c10f. Final documentation-only commit does not alter
the tested app or QA host script; its diff is checked separately.
