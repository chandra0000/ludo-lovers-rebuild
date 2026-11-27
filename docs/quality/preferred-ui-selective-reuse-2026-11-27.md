# Preferred UI: selective reuse review

Owner direction: preserve the UI/screenshots behind PR94; compare and reuse useful
work rather than implementing or merging every pending branch.

## Verified source distinction

- Current main:5d4ca3fb79d29e6ae8365f119ba31c13bb7e4348.
- PR94 head:71e7d362e63fcb99d7854a75e99ec67ad028e476, draft. Its seven-file
  diff adds online authority, SQL, relay, workflow and documentation; no Flutter UI.
- Preferred application source is its PR92 parent:
  6f0479e3e2610fca2e741bd434973fb026061065. Its local UI, smaller74%-scale
  cube, capture retreat, lobby and typography already exist. Do not rebuild them
  or apply main's88% visual scale on top of the74% cube.

Actual393x873 Android installed screenshots from run45793334871, artifact
15102794846 were downloaded and inspected: native-ffa-match.png and
native-branded-home.png. These show the preferred composition and real fonts.
The capture source229817fe7e886f9449c5bc89b7f48927348e160e has the same application
code as parent6f0479e; the latter changes only an app test. They are historical
software/debug emulator evidence, not a new recording or physical acceptance.

[Screenshots](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45793334871/artifacts/15102794846)

## Reuse decisions

| Area | Decision | Reason |
| --- | --- | --- |
| PR92/94 inherited lobby, board/HUD, profiles, dice, capture presentation | Preserve | Owner's preferred existing design; do not recreate or compound dice shrinking |
| PR76 typography, branding, startup, chooser | Already inherited by preferred branch | Reuse existing implementation; no duplicate screen or wholesale older merge |
| Main native save-write fix | Carry into preferred branch | Native false must propagate to persistence controller; existing recovery regression reused |
| Main local-current version2 saves | Preserve decoding/configuration | Main has already created2/3-seat saves; preferred branch must not reject them on upgrade |
| Main security pins/advisory workflow | Preserve when integrating with main | Prevent reverting current supply-chain checks; do not reintroduce mutable tags |
| PR93 public Team Up | Hold release toggle for dedicated acceptance | Domain code exists; screenshot approval does not clear mode release gates |
| PR95 direct stack selection | Review only unique changes | Must retain accessible selection of every overlapping legal pawn; do not remove fallback solely for appearance |
| PR94 authority/session receipts and membership-scoped reads | Useful backend foundation, hold deployment | Static compilation is not hosted authentication, SQL/RLS or two-client acceptance |
| PR94 fees, wallet escrow and payout | Defer separate product/security review | Not required to finish reliable free local gameplay |
| Old renderer experiments and broad redesigns | Do not batch-merge | Keep useful diagnostics separate from the preferred UI; no failed gate is cleared |

## Small implementation in this follow-up

Only two production files change: SavedMatchStore checks native write acceptance,
and MatchConfiguration preserves main's exact version2 local seat/save contract.
The preferred Flutter presentation, board/logo assets, pawn geometry, sounds,
dice appearance/timing and rule profiles are unchanged. New tests cover two/three
seat saved snapshots, four-seat/Classic version isolation and native write failure
followed by recovery. This does not change public mode availability or the lobby.

## Merge and release constraints

A read-only merge preflight of PR94 against current main reports conflicts in
MatchScreen, GameSetupScreen and LuxuryDiceButton. Therefore do not replace main
with its tree or blindly merge the backend to obtain its inherited UI. Integrate
reviewed UI ancestors separately, preserving main's safety and save contracts.

PR92 run45793764102 passed format/analyzer/tests, but its profile build failed
fetching audioplayers_android Kotlin/JUnit dependencies from Maven with HTTP429.
That log establishes a dependency retrieval failure, not an application runtime
root cause. A fresh successful build is still required; no test is disabled.
PR94 run45854680886 passed authority static/compile checks only. Its README says
Flutter online wiring and hosted acceptance remain pending. The authority still
needs bounded body/upstream read deadlines, rate/concurrency protection and
executable SQL/RLS/retry/reconnect tests before production deployment.

Main's unresolved default-renderer Android acceptance, physical profile traces,
process-death recovery, screen-reader checks, signing/store and final owner
acceptance remain separate gates. No9/10 or production-ready claim is made.
No main merge or backend deployment is performed by this comparison.
