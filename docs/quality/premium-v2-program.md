# Premium Match V2 execution ledger

## Verified audit — 2026-11-17

Main `879f2b555c50575c5db066e0ac8bf530271a965a` contains #43, but not the
later #46–#53 application. Their merged statuses refer to stacked parent branches,
updated after #43 reached main. Compared with reviewed source
`8ad86d5372c7881b19f6c540bba7b0d26bc7d4e8`: diverged, 7 ahead / 3 behind.
Reconciliation retains both histories and main-only documentation; approved
assets, geometry and rules are unchanged.

Main foundation 44000165028 and cross-platform 44000164874 succeeded.
Android integration 44000164880 failed before Flutter: emulator booted, `/bin/sh`
rejected `set -euo pipefail`, then adb diagnostics stalled until cancellation.
Actual job 133761934821 logs establish this cause. Repair explicitly enters Bash
and bounds each diagnostic adb call to 15 seconds; no timeout increase or blind retry.

## Approved decisions

- Keep compatibility `ludo-lovers-current@1` default; Classic stays separate.
- Classic seats: 2 Orange/Magenta, 3 Orange/Green/Magenta, 4 all; skip absent seats.
- Quick: four yard pawns per participant; first to finish any two wins. Inherit
  Classic movement/capture/dice; no bonus after victory.
- Team Up: Orange/Magenta vs Green/Blue; scheduled seat differs from recipient.
  Use canonical priority-stack rules, not Classic hard blockades.
- Team Up uses legacy six/capture/finish bonuses and third-six forfeiture.
  Friendly departure losses are attributed to opposing priority team and do not
  grant the mover a capture bonus. This explicitly supersedes the legacy test
  that granted Green a bonus after losing Blue's pawn.

## Verified feature matrix

Classifications refer to audited main. Legacy reference is
`ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`; plans/dependencies are not implementations.

| Feature | Classification | Evidence / decision |
| --- | --- | --- |
| Compatibility local engine | Fully implemented and tested | Preserve authoritative MatchSession |
| Classic | Partially implemented | Profile/tests exist; opt-in acceptance open |
| True 2/3 seats | Missing | Legacy factory exists; fixed-seat extension now approved |
| Seeded AI difficulty | Fully implemented and tested | Legal Easy/Medium/Hard; add mode awareness |
| Persistence | Fully implemented and tested | Rebuild codec/store; device interruption acceptance open |
| Names / stable colors | Defective | Integration: #48 reviewed but absent from main |
| Latest dice / feedback settings | Defective | Integration: restore #49, do not duplicate |
| Stars / portrait / ten layouts | Defective | Integration: restore #50 |
| Restart / confirmed exit | Defective | Integration: restore #51/#52 |
| Team Up | Documented only | Real legacy rules/tests/navigation; migrate policies, not engine |
| Quick | Missing | No legacy executable mode; new two-finish decision approved |
| Tournament | Documented only | No progression implementation; product gate |
| Local chat / reactions | Fully implemented and tested | Keep local labels; legacy chat is unavailable online notice |
| Online Classic / rooms | Missing | Backend architecture review/credentials first |
| Friends / privacy / moderation | Documented only | No verified legacy service |
| Love Mode | Documented only | Optional vision; no approved executable mode |
| Onboarding | Fully implemented and tested | Retain live rebuild flow |
| Match history/statistics | Missing | Needs separate result policy |
| Renderer/device profiling | Deferred intentionally | #39 static harness is not physical evidence |
| Signing/device acceptance | Deferred intentionally | Hardware/credentials/owner gates |

## Dependency graph

Reconciliation/CI → orchestration → responsive HUD → materials → registry/Classic
→ Quick → Team Up domain → Team Up live UI → mode-aware AI → visual/device
acceptance → online architecture review → rooms/online Classic → tournament
specification → Love/social → release hardening.

Each increment gets a focused unmerged PR. Keep modes publicly unavailable until
acceptance; explicit internal builds may exercise completed flows. Never infer
physical acceptance, online security or 9/10 scores from automated checks.

## Reconciliation verification

Full suite, strict format, fatal-info analysis, assets and remote CI are checked
on the published candidate. Previously reviewed source had 334 passing tests;
that historical number is not assigned to main without execution evidence.

## Reconciliation and refactor evidence

PR #54 source `a8edd17362f1448b5460d990a89d5d71e5cabe95`: 334 local tests,
strict format and analysis pass. Remote foundation 44006421732, cross-platform
44006421737 and Android integration 44006508670 all succeeded. Emulator job
133783054945 reports `All tests passed`; installed navigation ran successfully.
This repairs the prior shell error, not a physical-device acceptance gate.

The next focused refactor extracts read-only pawn clustering/rendering,
geometry-based destination previews, result presentation and a turn coordinator.
MatchSession owns transitions; coordinator calls engine legal moves/events and
retains bounded AI/automatic scheduling, pause guards and disposal cancellation.
Accepted commands now use one persistence entry point. MatchScreen decreases from
42,980 to 28,497 bytes. Full suite: 336 tests pass in 85s; strict analysis passes.
All four mandatory captures have zero RGB differences against pre-refactor images.
New coordinator tests verify guarded randomness, repeated completion and disposal
of pending AI scheduling. Existing restore/exit/anchor regressions remain active.

## Responsive Premium Match V2

Live match HUD uses independent logical-pixel regions: all four fixed-identity
profiles above, a square stage containing the entire approved artwork, and dice /
status / local social settings below. The 576×1024 reference canvas remains inside
one uniform board transform; the visible square stage, not that reference canvas,
is the viewport containment contract. Existing logical artwork registration and
pawn anchors remain unchanged. The source portrait canvas capture is retained for
calibration evidence. Old position-only tests now check the visible board stage;
no coordinate or hitbox assertion is removed.

Ten responsive fixtures assert square stage, full artwork containment, all four
names above square avatars in authoritative order, profiles above artwork, controls
below the stage and 48dp primary targets. Enlarged-text and legal chooser behavior
remain tested. Actual 320×640 and 393×873 rendered captures inspected; no owner
9/10 visual approval is implied. Exterior HUD lighting is independent of artwork.
