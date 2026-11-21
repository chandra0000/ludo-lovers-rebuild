# Actual Android gameplay recording

## Source and limits

QA is stacked on PR #74 (`70f0bf2051c405d405079f7de20b42fa7daac2fb`),
whose application source is the enlarged-profile/centered-logo UI from PR #73
(`50ae0cf14ac4e7a66cc56e9599cb6c90971aff2b`). Main remains
`879f2b555c50575c5db066e0ac8bf530271a965a` at this audit. No AGENTS.md was found
in the repository or workspace parents. Read architecture/architecture.md,
DECISIONS.md, engineering/development-and-testing.md and release gates first.
The only production Dart change pairs dark/gold SnackBar colors after native
recording exposed low-contrast feedback; a regression test covers it. Artwork,
geometry, rules, pawn/dice rendering and availability gates are unchanged.
See [the final verified QA report](android-gameplay-qa-report-2026-11-21.md) for
the inspected corrected recording and exact commits.
Public compatibility and internal Classic/Quick/Team-Up remain distinct.

This cloud environment has Flutter3.35.7/Dart3.9.2, Java21 runtime, ADB and
ffmpeg/ffprobe, but no /dev/kvm or Android emulator binary. Android execution is
therefore delegated to the dedicated CI recording job, not represented by desktop
or widget-test footage. Physical-device acceptance remains incomplete.

## Run

In GitHub Actions select **Android gameplay recording (seeded QA)** and dispatch
on the QA branch after that workflow is available on the default branch. Before
merge, add the `run-gameplay-recording` PR label to run the PR's workflow. Each
run builds the integration APK before booting an API33/google_apis/x86_64 Pixel2
emulator with software OpenGL/SwiftShader and KVM. Native animations remain enabled.
The app is debug-mode, with internal modes and the recording fixture explicitly
compiled into the integration target only. Normal release behavior is unchanged.

For an already booted local emulator, from apps/mobile:

```bash
flutter build apk --debug --target-platform=android-x64 --target=integration_test/app_navigation_test.dart --dart-define=LUDO_ENABLE_UNRELEASED_MODES=true --dart-define=LUDO_RECORD_GAMEPLAY=true
LUDO_GAMEPLAY_RECORDING=true LUDO_SOFTWARE_RENDERING=true bash ../../.github/scripts/android_integration.sh
python3 ../../.github/scripts/verify_gameplay_video.py test-artifacts/gameplay/gameplay-android.mp4
```

Use Android SDK/JDK and pinned Flutter prerequisites from the development handbook.
The reproducible CI configuration includes bounded Gradle memory and prebuild
isolation inherited from #74. The recording uses native Android `screenrecord`,
SIGINT finalization, process-exit checks, then `adb pull`. It never generates,
interpolates, crops or reconstructs gameplay frames. Current target capture360×800 at
160dpi is a360×800 logical display before Android system/safe-area insets; physical
recording resolution and actual frame rate must be read from ffprobe.

## Deterministic demonstration

One integration-only scenario uses production widgets/MatchSession/animations:

1. Home, then fresh compatibility FFA with names Aarya, Renée, Maya and Leo.
2. Inject human rolls6,3: choose a yard pawn, release to0, travel to3 and handoff.
3. Explicit staged capture fixture: Orange[0,-1,-1,-1], Green[42,10,-1,-1],
   others in yard. Human rolls3,2,1; production medium AI Green uses seed17.
4. Capture Green pawn0 at shared cell3, retain the capture bonus, move Orange to5;
   Green AI rolls4 and moves pawn1 from10→14, handing off to Magenta.
5. Magenta rolls1, has no legal move and passes to Blue. Save/restore codec/state
   equality and stable profile identity are asserted. Hold a complete portrait frame.

The staging is a disclosed transition between fixtures inside a continuous native
recording, not a claim of a naturally played complete match. No dice fairness or
capture policy is changed. Only the test's injected rolls differ from ordinary play.
Repeated roll/pawn taps, exact state versions, dice target, pawn progress, capture
and extra-turn events, AI move/handoff and saved state are asserted. The same
scenario runs as a fast widget regression with simulated elapsed time; that pass
is not Android runtime or video evidence.

The existing three installed navigation/mode/social tests still run and require
all eight native PNGs, including Classic2, Quick3 and Team-Up4 setup/roll/restart/
resume flows. Full suite retains geometry, home-lane, stacks, command idempotency,
lifecycle and victory/rematch coverage. These are separate from what video shows.

## Capture and failure diagnosis

Historical run44523207613 was downloaded and inspected (diagnostics artifact
14529292713, SHA256836100229146c891c0cd43e498798a021fd1acf82ee03a2764311d745f498d98).
It contains no recorded kernel OOM kill, native QEMU summary or recoverable guest
logcat after loss. ColorBuffer23/invalid-texture errors occurred during emulator
boot before application launch; they are clues, not proof of an application cause.
Driver disappearance/ADB offline/TCP5554 refusal are downstream loss symptoms.

The focused capture-path experiment retains the same UI/renderer/emulator and
required screenshots but replaces Android Flutter image-surface conversion with
native ADB display captures. iOS retains its existing supported capture path.
A live logcat collector and integration transcript survive a later ADB loss.
This is not a proven root-cause fix until current runtime evidence exists.

Native fonts are used in installed screenshots. Fast widget tests normally use
Ahem (block-like text); the responsive capture suite explicitly loads SDK Roboto,
MaterialIcons and available OS emoji fonts. Readability still requires inspection
of actual native frames; widget glyph artifacts cannot approve installed UI.

## Artifacts and acceptance

The workflow uploads gameplay-android.mp4, authoritative-events.json, integration
and live Android logs, exact checkout/app-lib-tree metadata, complete-decode/fps/
codec/change validation and representative unretouched frames, with30day retention.
Eight required installed PNGs are uploaded separately; none is disabled.
The normal foundation workflow captures320×640,360×800,393×873,430×932 logical
viewports plus extended cases. Those widget-rendered PNGs are not physical captures.

Automated validation requires45–95seconds, portrait H.264, valid positive
frame rate, full-stream decode, sustained active frames and at least20 distinct
half-second samples. It reports the30fps cadence target separately from idle-inclusive
variable-rate averages; missing that target remains an explicit limitation. This rejects frozen
or corrupt output, but visual review of dice/motion/landing/capture/readability is
still required before reporting an inspected recording. Recording overhead is not
an app-performance benchmark. Owner visual sign-off, physical hardware, production
signing and other release gates remain unchanged.

Current execution receipts and any failure must be attached to the QA PR before
claiming Android/video verification. Do not merge automatically.

## Local execution checkpoint

447 tests pass locally, including the shared seeded gameplay fixture; strict
formatting and fatal-info analysis pass. Five host recorder checks verify SIGINT
and process-exit ordering before pull, idempotent cleanup, duplicate-start rejection
and invalid capture rejection. The recording explicitly enables the live binding's
fullyLive policy for its duration, restoring the prior policy afterward; the SDK
default fadePointers policy cannot be used as evidence of continuous animation.
Existing installed navigation also edits Unicode player names during setup.
No production source or asset bytes changed. CI run44865723200 is the initial
capture-path experiment; its original fixture predates the explicit live-frame
policy and must not be promoted as final motion acceptance. Final run/commit/video
receipts will be recorded separately after inspection.

Run44865723200 reached native recorder startup but failed the new host parser:
Android truncated a long JSON log message at approximately1KB. Its cleanup query
also exceeded the original3second ADB probe. No MP4 was pulled; this is failed QA
transport evidence, not an emulator-root-cause conclusion. Snapshot transport now
uses numbered480character base64 chunks with reassembly/corruption/missing-part
checks. The cleanup query uses the same bounded15second ADB budget as the other
native operations, preserving the primary failure if cleanup also fails.

## Bounded renderer isolation

Run44866649368 on QA sourceb516385cc20388d0aec700049f4971759150e1ef
reassembled the snapshot correctly, then lost the driver/ADB/QEMU before any dice
roll. Its sole native PNG is black except system bars and is rejected as gameplay
evidence. Capture-path changes alone do not resolve the historical runtime loss.
There is still no native crash stack establishing its underlying cause.

The next run changes only Flutter's runtime renderer: the same APK is launched
with --enable-software-rendering --no-enable-impeller. The dedicated workflow
sets LUDO_SOFTWARE_RENDERING=true; the regular checkpoint keeps its original
renderer configuration. This flag is supported by pinned Flutter3.35.7 for Android
emulator debugging, not used in production builds. Any resulting footage must be
labelled **Android emulator / Skia software / debug**. It cannot approve production
OpenGL/Vulkan or physical GPU performance. Launch argv/configuration is retained.

The new Unicode setup check exposed a harness finder error on iOS in
run44865991872/job136731488302: after collapsing the editor, the lazy ListView's
start card was unmounted, so ensureVisible threw No element at line98. The test
now returns the setup scroll position to the top and uses bounded scrollUntilVisible
to build/find the actual start card. The name-editing check remains enabled; no
production layout or navigation is changed.

## Native software-renderer result and recording-quality correction

Run44867719937/source35990cac78156f51c2cccc505841b2ed63a425ea
produced a genuine finalized16.519second portrait H.264 MP4 at786×1746,
readable native names/avatars/board and all eight installed PNGs. All three existing
navigation/mode/social tests passed without emulator loss. The new demonstration
failed a timing assumption (expected pending version3, actual already-accepted
move version4); it did not fail a gameplay rule. The short video is rejected for
requested duration. Its authoritative snapshots and actual native frames were
inspected. Default-backend logs identify Impeller/OpenGLES; software Skia succeeds
in reaching/rendering the same match. This is renderer-path isolation evidence,
not proof of the exact historical native QEMU crash or physical GPU acceptance.

The demo now asserts the exact accepted roll snapshot/event/command count and
compares the displayed pending value with current authoritative state even when a
legal automatic move has already completed. Duplicate-roll version and subsequent
movement/capture/turn assertions remain mandatory. No production timers change.

Native screenrecord is variable-rate: the short file averages4.843encoded fps
because idle screens produce no new buffers; its active intervals nevertheless
measure only about10.27fps under software debug/recording load. This does not meet
the30fps target. The next capture uses360×800 physical pixels/160dpi (360×800
logical display, actual app window/system insets reported separately), reducing
software raster/encoder work instead of synthesizing/interpolating frames. The
validator reports both encoded average and median positive intervals<=150ms,
explicitly excluding idle holds; it records whether the30fps target was reached.
It still requires duration, full decode, H.264, portrait, sustained changing frames
and visual review. Low cadence is reported as a limitation, never a performance
pass. No frame-rate conversion is applied to the deliverable.

## Recorder completion contract

Run44868357623 reached the AI handoff and no-move pass, but its background recorder
failed the bounded SIGINT finalization/process-state poll. No MP4 was pulled or
accepted. The recorder now runs in the foreground on a dedicated ADB connection:
print the remote shell PID, exec screenrecord in place, SIGINT that exact process,
and require successful connection/process exit before pull. This removes shell
background signal inheritance and /proc polling races without extending the12second
finalization bound. Tests reject nonzero exits/timeouts and prove signal→wait→pull
ordering. The emulator runner cleans the guest even on failure. The exact underlying
prior flush/poll failure remains unproven; the foreground contract is the correction
under test. Device properties collected at launch are preserved separately from
post-emulator diagnostics, and artifact names identify the actual QA checkout.

## Established file-finalization failure and focused correction

Run44869475517/source50fd5f5e1dad405e00f56f9e13d184f14ca8dfe3
proved the native writer completed: recorder PID3957 logged all tracks stopped
Status0,56801118us duration, MOOV written, final fsync and exact2628699byte file
at05:21:04.304UTC. It then hung after MediaCodec flushMediametrics; waiting for
process exit rejected a file already finalized. A second signal during failure
cleanup exited130. The emulator/app remained alive. The full recording was not
pulled in that failed run and is not delivered as evidence.

The correction keeps the original12second stop budget: send SIGINT once, poll
successful exit OR recorder-PID-scoped MOOV+final-fsync evidence plus an exact
remote stat size match. Only after durable-file proof may a stuck codec process
be killed, then the file pulled and fully decoded. Nonzero exits/timeouts without
proof still fail. Finalization mode, native writer log and exit code are retained.
This fixes the host's incorrect completion proxy; it does not claim a native codec
teardown fix. The test waits for a bounded debug-app cache acknowledgement after
pull, preventing later screenshot scenes from advancing during host cleanup.
No production timers, gameplay, test disablement or stop-timeout inflation.

## Verified native baseline and visual review finding

Run44871386017 on QA source45448df3586a19a1df481bb5096a06c074f76b06
passed all four installed scenarios and required PNG checks. Its genuine raw
55.232411second360×800 H.264 MP4 fully decodes:615 strictly increasing input
packet timestamps,71 distinct half-second samples,11.135encoded fps including
idle holds and28.423fps median active intervals. The30fps target is not met and
is not represented as a production-performance pass. Native emulator37.3.10.0
build16970787, Android13/API33 imageTE1A.240213.009/12342917, Skia software/debug.

Recorder PID3956 completed MOOV/fsync at3003818bytes, then required post-file
codec cleanup (exit137), explicitly recorded in recorder-finalization.json. The
MP4 SHA256 is92d31540d0e283f36d5726d8f59e24bb8f479a8278a554d52883a597e8a2cdc0;
artifact14694675627 ZIP SHA256dd5a06acd5e92459f01556499aef126a3dabc617188ebad762096a32bc8097e6.
Frames7/10/22/26/34 were inspected: actual six, yard release, capture setup/result
and AI-to-human handoff. The approved board/slots/names are intact. A dark-on-dark
transient snackbar is a real Material3 theme contrast defect, not an Ahem-font
artifact; the next focused change defines paired dark background/gold foreground
in the production snackbar theme and adds a resolved-rendered-text contrast test.
It does not change assets, geometry, gameplay or pawn/dice styling.

For independent full decoding, preserve the demux timebase and pass through VFR
timestamps. A null output with its inferred low average frame rate otherwise
prints duplicate output-DTS rounding warnings despite strictly increasing input
packet DTS. The corrected command decodes all video frames with zero stderr; it
does not transcode or alter the deliverable. Final corrected-UI recording receipts
will be attached after actual execution/inspection.

Run44874091176 on corrected-UI sourcead16fed reached every gameplay assertion
and again proved a finalized59661959us/2336687byte MP4. Its dedicated ADB recording
client did not exit within3seconds after the remote recorder kill, so the run
failed before pull. The completion path now closes only that dedicated client
after native MOOV/fsync/size proof and remote cleanup; the application/driver and
ADB server remain untouched. The regression checks this lingering-client case and
rejects a remote file-size mismatch. No wait bound or gameplay changes.
