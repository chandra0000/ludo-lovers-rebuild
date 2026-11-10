# Ludo Lovers device profiling and validation

This guide separates automated rule simulation from rendering measurements that must be collected on a real Android device.

## Known baseline

- Canonical board asset: `assets/images/board/ludo_board_glass.webp`
- Verified asset dimensions: 810 × 1440 pixels (9:16).
- Asset file-size regression test: below 300 KiB.
- Logical match canvas: 576 × 1024.
- Board geometry remains provisional: `BoardGeometry.visualApprovalPending` must stay true until a human visually compares the overlay with the source artwork on a device.
- Pawn hit regions are currently 44 × 48 logical pixels; compact stacked-pawn coverage checks this contract.
- Domain stress coverage already exercises at least 2,500 deterministic transitions. It is not a claim that 100-turn AI games, device memory, haptics, or audio have been physically validated.

## Pixel calibration procedure

1. Open the in-app Board Preview on a device and capture the full 9:16 artwork without cropping or display scaling.
2. Record the artwork's actual pixel dimensions from the decoded image (currently guarded by `gameplay_artwork_asset_test.dart`).
3. Compare the overlay centres with the artwork centres for the finish emblem, all 16 yard sockets, the eight safe stars, and connector transitions 4, 17, 30, and 43.
4. Convert screenshot pixels back to the 576 × 1024 logical canvas using the measured image scale and letterbox offset. Do not infer offsets from a resized chat preview.
5. The renderer now uses one source-pixel anchor table for the 52 shared-track cells, 20 home-lane cells, finish centre, and 16 yard sockets. Do not reintroduce a uniform square-grid transform or duplicate coordinate maps in widgets.
6. Compare every marker against the canonical source at full resolution. Record residual offsets in source pixels and design-canvas units; update only the centralized `BoardGeometry` anchors.
7. Save before/after screenshots and record measured deltas. Keep `visualApprovalPending` true until a human confirms alignment on a physical device.

## Android profile-mode measurement

From `apps/mobile`:

```bash
flutter pub get
flutter run --profile
```

Use Flutter DevTools Performance and Memory views while repeating:
- rapid single-pawn hops;
- two pawns sharing a tile;
- four pawns sharing a tile;
- repeated match exit/re-entry.

Record UI-thread and raster-thread frame times, missed frames, allocation/GC spikes, and memory before/after repeated match resets. Optimize cluster layout only if measurements show UI-thread work above 8 ms per frame or reproducible jank. The current game has only 16 pawns; source-level operation counts alone are not a substitute for device profiling. The board image is already isolated beneath `RepaintBoundary(key: Key('match_canvas_capture'))`; verify raster behavior in the timeline rather than assuming the boundary eliminates all repaint work.

## Automated checks

```bash
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter test integration_test/app_smoke_test.dart -d <device-id>
```

The domain stress test validates deterministic state-version progression and invariants. Keep AI simulation bounded and seeded; do not make CI depend on an unbounded four-player match reaching a winner. A separate AI match-completion benchmark should report a fixed turn/time limit and outcome rather than hang.

## Physical device and haptics/audio

Build a profile APK and install it on the target phone:

```bash
flutter build apk --profile
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

On the phone, test touch selection, TalkBack traversal, dice announcements, haptic feedback, sound, repeated match resets, thermal behavior, and memory. Emulator/headless tests can verify that hooks are invoked, but cannot prove that the handset physically vibrates or that its speaker output is audible. Record Android model/version, refresh rate, battery mode, and test duration with results.

## Current limitations

No GPU/raster timings, memory-leak result, haptic confirmation, sound confirmation, or physical installation result should be reported until the corresponding device run has actually been performed.