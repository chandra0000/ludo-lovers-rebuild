# Current main: preserve preferred UI and reuse selectively

Live GitHub review baseline:383901751f1f3a2c783c8b707e3b3b77f5dc5cad.
PRs74,75,76,92,93,95,105 are already merged. Follow
[the post95 policy](../engineering/post-95-integration-plan.md): current main is
the only implementation base; do not replay historical UI stacks.

Earlier connector snapshots showed5d4ca3 and an open92. Direct live GitHub REST
and git fetch established the newer baseline. PR106 was closed without merging
because its two production changes already exist in main. No force push or old
UI/tree replacement was performed. Earlier unmerged76 worktrees remain isolated.

## Selective reuse

| Work | Current decision |
| --- | --- |
| Preferred lobby, royal board/HUD, typography, capture retreat, dice, branding | Already integrated; preserve current main's actual implementation |
| Local2/3, opposite Orange/Magenta duel, Unicode names, version2 save compatibility | Already integrated; preserve and verify existing saves through the current UI |
| Native write-failure propagation, security pin/advisory checks | Already integrated; do not duplicate or revert |
| Public Team Up and direct clustered-pawn selection | Already merged in93/95; preserve current release status and direct selection; do not restore the old chooser |
| PR94 online backend | Draft, separate authority/security review; it adds seven backend files and no Flutter UI over its92-era parent |
| PR94 wallets/fees/payout | Not needed for stable local gameplay; do not bundle with authentication/private-room foundations |
| PR39/40/42 and old renderer experiments | Reference and compare unique changes; no wholesale merging or renderer replacement |

The inspected393x873 Android screenshot artifact15102794846 from run45793334871
shows the preferred92-era lobby/match UI. It is historical software/debug evidence,
not a fresh current-main recording or physical acceptance. Main includes later95
selection changes, which must be preserved.

## Useful change implemented now

Add frozen old-main local2/3 saves containing an accepted pending six, plus two
widget upgrade regressions. Tests resume through current HomeScreen, preserve
configuration/version/Unicode names and dice6, reject a duplicate roll, then accept
exactly one yard-release move despite repeated taps. Fixtures come from the old
serializer, not the current code under test. No production, artwork, geometry,
rule, persistence implementation, mode availability or design file changes.

## Evidence and remaining work

At live review, current-main foundation46045154508 and Android checkpoint46045154458
passed. Cross-platform46045154513 subsequently completed both Android and iOS
acceptance jobs successfully. These receipts apply to3839017, not future changes. Do not repeat the obsolete claim
that74–76 remain unmerged or that every current default-renderer run fails.

Next local release gates: final installed device matrix, real process-death and
low-memory restoration, long-match/rematch soak, TalkBack/VoiceOver, physical
profile-mode frame/memory/audio traces and owner visual acceptance. Widget fixture
restoration alone does not clear them. No9/10 or production-ready score is assigned.

After local acceptance, audit94 against90 before choosing/deploying authority.
Require total body/upstream deadlines, rate/concurrency limits, hosted SQL/RLS and
concurrent/idempotent command tests, authenticated two-client reconnect/resume and
an implemented Flutter transport. Static compilation is not online acceptance.
