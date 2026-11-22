# Gameplay recording QA and remediation — 2026-11-22

## Evidence and scope

Reference: `gameplay-android.mp4` supplied in the owner's ChatGPT Library. This file is not checked into Git. Review is a visual sampling, not a deterministic test run or proof of device-level performance.

This PR deliberately addresses one source-confirmed accessibility defect: the pawn hit target used a 44 dp minimum width while the design requirement is 48 × 48 dp. The widget now uses a minimum of 48 dp on **both** axes after canvas scaling. This is a focused improvement; it does not prove adjacent targets are non-overlapping or that all controls pass TalkBack.

## Preservation rules

- Preserve canonical full-portrait glass board image and original pixel contents.
- Keep board topology and 52-track-cell / home-lane anchors authoritative; do not infer alignment from a resized video.
- Preserve orange, green, magenta, blue **turn order** and existing board quadrant placements (orange top-left, green top-right, blue bottom-left, magenta bottom-right).
- Keep `MatchSession` authoritative, with no UI-derived rule changes.
- Do not silently enable Classic rules, Team-Up, online matchmaking, or Flame renderer migration.

## Recording-derived follow-up acceptance backlog

| Priority | Area | Verification and exit gate |
| --- | --- | --- |
| P0 | Board/pawn calibration | Pixel-overlay inspect all 16 yard sockets, 52 shared cells, 20 home-lane anchors, and finish on source artwork; get owner sign-off |
| P0 | Dice / turn controls | Verify 48×48 dp minimum tappable regions, disabled states during animations, and explicit Roll Dice / Choose a Pawn / AI Thinking status |
| P0 | Pawn interaction | Validate adjacent targets, stacked pawn chooser, semantic labels and no accidental moves across 320×640, 360×800, 393×873, 430×932 |
| P1 | Adaptive HUD | Use screen-height budget outside the authoritative board; avoid duplicate baked-in HUD elements, cropping, overlap, or illegible names |
| P1 | Motion | Capture deterministic roll, hop-by-hop movement, capture, win, restart, lifecycle resume; measure frame pacing on a physical Android device |
| P1 | Player names / AI | Validate dynamic names, color association, AI identification, contrast, text scale and TalkBack |
| P2 | Art direction | Refine 2.5D pawn depth and gold dice only after parity screenshots confirm the board artwork remains unchanged |

## Current change and verification status

- **Implemented:** pawn touch targets use a minimum of 48 × 48 dp in design-to-device scaling.
- **Not executed in this session:** `dart format --output=none --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`, Android emulator integration, profile/release APK builds.
- **Not completed:** physical-device validation, screenshot sign-off, full backlog above.
- Do not call this PR a complete video-issue fix or production release gate.

## Required CI and device checklist

Run from `apps/mobile`: `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze --fatal-infos`, `flutter test`, and the repository Android integration / profile / release workflows. Capture side-by-side screenshots and a fresh recording on representative 6.1–6.9-inch phones; compare with the original recording. Track failures as separate scoped PRs rather than merging unverified broad redesigns.

## Follow-up implementation: editable local player names

- Match setup now offers optional, 20-character name fields for all four colors, in canonical turn order.
- Whitespace is trimmed before passing names to `MatchScreen.profiles`; blank names retain the existing color defaults.
- AI-controlled seats retain their bot labels regardless of text entered in setup.
- Added `apps/mobile/test/game_setup_player_names_test.dart` for local-name propagation and AI-seat identity behavior.
- **Validation pending:** Flutter formatting, analyzer, widget tests and device screenshots were not executed here. Verify field scrolling, keyboard insets and profile text truncation on compact portrait phones.

## HUD quadrant correction

- Corrected the profile presentation positions: orange top-left, green top-right, blue bottom-left, magenta bottom-right.
- This is a presentation-only correction; engine turn order remains orange → green → magenta → blue.
- Added `apps/mobile/test/match_profile_quadrants_test.dart` to guard the approved seat coordinates against regressions.
- Pending: execute the widget test, check actual artwork overlay, inspect full-size and compact portrait captures, and verify there is no HUD overlap.

## Responsive HUD, motion and calibration instrumentation follow-up

- Profile badges now proportionally divide their fixed design-canvas width between player identity and status; this reduces name/status collisions while preserving the authoritative canvas and approved board art.
- The luxury die now applies a small lift-scale pulse during the existing engine-result-driven tumble. No additional roll or random face is generated; reduced-motion users continue to receive the settled result without a tumble.
- The moving pawn now has a small per-cell vertical hop, calculated from the existing presentation controller and disabled when system reduced motion is requested. BoardGeometry remains the source of truth for movement coordinates.
- The assert-only `LUDO_DEBUG_BOARD` overlay now draws 52 track positions, 20 home-lane positions, 16 yard sockets and the finish anchor, enabling a complete side-by-side alignment audit. **Overlay presence is not evidence that alignment is correct.**

### Validation / device test procedure (not yet executed)

1. Run `flutter test`, `flutter analyze --fatal-infos` and repository CI against this PR.
2. Launch a debug build with `--dart-define=LUDO_DEBUG_BOARD=true` and capture screenshots on 320×640, 360×800, 393×873 and 430×932 layouts; check all 89 anchors (52+20+16+finish) against the approved board art.
3. Capture roll, same-value consecutive rolls, six-step movement, capture, finish, restart, background/resume, and TalkBack/reduced-motion runs. Verify that each accepted engine roll generates exactly one animation-completion callback and that the pawn lands on the authoritative destination.
4. Verify all four profile badges remain readable and non-overlapping, and that the board is never cropped or stretched. Test on physical Android phones and an iOS simulator/device where available.
5. Record test outputs, screenshots, device models, frame times and owner acceptance before marking these items complete. No device/emulator execution was available in this editing environment.
