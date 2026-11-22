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
