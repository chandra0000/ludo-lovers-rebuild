# Android gameplay recording — verified evidence

## Sources and review order

Recorded QA commit: `bdf08df75fdba52fbea9a889ff43e74e1b62dc58` on
`qa/android-gameplay-recording`. Application code is unchanged from
`ad16fed5e9327c4211c6916c0b8e4b7c4f723867`; application lib tree:
`cb173caba2791e942fe2c4c0701d648be1d385ba`.
The enlarged-profile/centered-logo application comes from PR #73,
`50ae0cf14ac4e7a66cc56e9599cb6c90971aff2b`, with PR #74 Android build isolation
`70f0bf2051c405d405079f7de20b42fa7daac2fb`. Audited main was
`879f2b555c50575c5db066e0ac8bf530271a965a`; it is not presented as this UI.
PR #75 is stacked on #74. Review existing predecessors, then #73 → #74 → #75;
none were automatically merged. Later documentation-only commits are not the
recorded binary's source.

## Deliverables

**VERIFIED COMPLETE:** native continuous MP4, deterministic actual-app integration
fixture, reusable host recorder, dedicated workflow, native screenshots, responsive
widget captures and full-stream decode/frame review.

- [Successful native recording run](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368)
- [Download video, assertions and diagnostics ZIP](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368/artifacts/14695484241)
- [Native screenshots ZIP](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368/artifacts/14695807675)
- [Focused PR #75](https://github.com/chandra0000/ludo-lovers-rebuild/pull/75)
- [Recording usage and investigation history](android-gameplay-recording.md)

Artifacts retain 30 days. Local delivered file:
`apps/mobile/test-artifacts/gameplay-android-final/gameplay-android.mp4`.
MP4 SHA256: `405a2c00169043e8bf422e75a25d380f134cfeee25c77e0dd21eb552f33d21c5`.
Video ZIP SHA256: `2c2e73a415d4ec3b19f932be180e0a6c55bad222aec84340f13fbe5d4582dcc1`.

## Runtime and video inspection

Android 13/API33 google_apis x86_64, Pixel2 emulator profile, emulator
37.3.10.0 (16970787), Linux/KVM. Display overridden to 360×800 physical pixels,
density160 (DPR1); system bars/insets remain present. Flutter3.35.7/Dart3.9.2,
debug integration APK, Skia software renderer (`--enable-software-rendering
--no-enable-impeller`). Production renderer configuration is unchanged.
Integration target: `integration_test/app_navigation_test.dart`; compile flags
`LUDO_ENABLE_UNRELEASED_MODES=true`, `LUDO_RECORD_GAMEPLAY=true`.

Native Android screenrecord output is H.264, 360×800 portrait, 58.7413 seconds,
2,595,819 bytes. No generated/interpolated footage or screenshot slideshow is
used. All 538 packet DTS values increase strictly. Entire stream decoded with
zero errors using preserved VFR timestamps; 68 distinct half-second frames.
Average encoded cadence is 9.16fps including idle holds; median active cadence
20.67fps (positive frame intervals ≤150ms). **30fps target NOT MET.** Recording
and debug/software overhead are not a physical-device performance benchmark.

Inspected actual extracted frames and motion sequences: anticipation/rotation,
settled six, yard release, three-cell traversal and landing, capture feedback,
AI travel and human handoff. Full board/HUD is visible and names/icons readable;
no Ahem/block glyph artifact in native captures. Final gold EXTRA TURN and
CAPTURE! EXTRA TURN messages are readable. Review frames are extracted from the
raw video; the video itself is unchanged. This is full-stream decode and sampled
frame/motion-sequence inspection, not a claim of interactive GUI playback.
Owner visual approval and board release acceptance remain pending.

## Disclosed deterministic fixtures

Both fixtures reuse production MatchScreen, MatchSession, geometry, painters and
normal animation durations. No production random source or rule profile changed.

1. Fresh compatibility FFA, names Aarya/Renée/Maya/Leo, human rolls6,3. Orange pawn0
   releases to0, then moves to3; active player becomes Green. Accepted versions0–4.
2. A new staged compatibility match starts in the same recording: Orange progress
   `[0,-1,-1,-1]`, Green `[42,10,-1,-1]`, other pawns in yards. Green is now a
   medium AI (seed17); this deliberate fixture replacement explains its BOT badge.
   Human rolls3,2,1. Orange0→3 captures Green0→yard on unsafe shared cell3,
   retains the bonus turn, then moves to5. Green AI rolls4, pawn1 goes10→14,
   hands to Magenta. Magenta1 cannot move and passes to Blue. Versions0–8.

Authoritative snapshots/events, displayed pending dice, accepted command versions,
active players, captures and final positions are asserted. Repeated roll/move taps
must not create duplicate commands or overlapping accepted moves. The video is a
seeded demonstration, not an unseeded full match or online-service acceptance.

## Verification scope

| Scenario | Status | Evidence / limit |
| --- | --- | --- |
| Home/setup/local entry and editable Unicode names | PASS | Installed integration tests, repeated exits |
| Dice animation and authoritative result | PASS | Native video and session assertions |
| Yard release, route movement, landing, turn progression | PASS | Video and state assertions |
| Capture, bonus turn, no-legal-move pass | PASS | Staged fixture and typed events |
| Repeated roll/pawn taps | PASS | Accepted-version assertions |
| AI thinking/roll/move/human handoff | PASS | Seed17 medium AI, native video |
| Compatibility FFA, Classic/Quick/Team-Up, computer flows | PASS | Installed setup/roll/restart/save-resume tests; alternate modes internal preview |
| Local chat and emoji | PASS | Installed captures; no online messaging claim |
| Saved names/state restoration | PASS within tested scope | Same-process preferences-backed restore and unit codec tests |
| Home lanes, stacks/chooser, wins/rematch, stale commands/lifecycle | PASS at unit/widget level | Complete suite; not all shown in native video |
| Real process death and OS lifecycle recovery | BLOCKED / unverified | Not established by same-process restore |
| 30fps capture target | FAIL | 20.67fps median active cadence |
| Default production GPU renderer | BLOCKED | Prior emulator/driver loss remains unexplained |
| Physical Android/iOS and owner visual sign-off | BLOCKED | No physical hardware/owner acceptance evidence |

448 local Flutter tests and 11 host protocol tests passed. Strict Dart formatting,
fatal-info analysis, Python compilation, shell syntax and workflow YAML checks
passed. All eight required native PNGs and 37 responsive/flow PNGs decode; the
mandatory logical widget viewports320×640,360×800,393×873,430×932 pass the existing
artifact verifier. Widget dimensions are not physical-device evidence.

- [Foundation checks, profile/release APK and AAB](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875002912): SUCCESS.
- [Android debug and iOS simulator build/installed checks](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875002916): SUCCESS after targeted Android dependency-resolution retry. Kotlin Maven/plugin POMs were verified accessible before retry; no test was disabled.
- Native recording run above: SUCCESS, four installed scenarios plus teardown.
- Default-renderer opt-in checkpoint was skipped, not passed.

## Diagnosed fixes and remaining failure boundaries

- Android truncates long test log records: numbered bounded snapshot chunks now
  reconstruct and validate JSON; missing/duplicate parts fail explicitly.
- Native realtime can advance beyond a pending-roll snapshot before host capture:
  assertions inspect accepted version history and displayed authoritative dice.
- Collapsing the setup name editor can unmount the lazy Start card while IME
  closes: shared bounded reveal/unfocus helper repairs test navigation.
- MPEG4Writer can finish MOOV and final fsync while recorder codec/ADB client
  teardown lingers. Recorder now requires PID-scoped writer completion and exact
  remote file size before targeted remote/local recorder cleanup, pull and app
  acknowledgement. It never substitutes a successful timeout for proof.
- Actual native capture exposed low-contrast feedback text. The only production
  Dart change sets paired dark/gold SnackBar colors in app.dart (six lines), with
  a red/green ≥4.5 contrast regression test. Board/logo/engine/geometry/pawn/dice
  sources are unchanged.
- Naive ffmpeg null-output timestamp rounding produced warnings despite increasing
  source DTS. Verification now preserves demux timebase; raw MP4 is not transcoded.

Earlier default Impeller/OpenGLES runs lost driver/ADB/emulator and produced a black
frame. Historical ColorBuffer errors also occurred before app startup; no kernel
OOM or conclusive crash stack established the underlying cause. Software Skia is
a disclosed QA launch configuration, not a proven production GPU fix.

Board SHA256 remains `f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`;
logo remains `ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793`.
Quadrant identity and Orange→Green→Magenta→Blue order are preserved.
No release, physical-device, geometry or visual-approval gate was cleared.
**Verdict: QA recording delivered; production release acceptance remains incomplete.**
