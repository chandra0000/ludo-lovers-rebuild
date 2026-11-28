# Production readiness: evidence review, not release approval

Baseline46c8bcb52cbee19e1d7b16bd6f523f22c62f7456. Owner authorized reviewed
merges. The9.5 target is not awarded. Scores below are provisional engineering
judgments, not measured market competitiveness or physical-device approval.

| Category | Score/10 | Evidence and remaining limit |
| --- | --- | --- |
| Architecture |8.0| Pure MatchSession boundary/import tests; MatchScreen orchestration still large |
| Engine |9.0|3030 completed seeded matches,30 configurations; no formal exhaustive proof |
| Gameplay correctness |8.5| Duplicate/stale/codec/mode regressions; native process-death/soak still open |
| Local modes |8.0| Local2/3/4, opposite2 seats, versioned Classic/Quick/TeamUp and seeded AI; broader human acceptance pending |
| UI/UX |7.5| Accepted royal composition/readable installed captures; final owner review and expanded results pending |
| Board fidelity |9.0| Canonical artwork/geometry tests preserved; physical alignment acceptance pending |
| Animations |7.0| Engine-driven motion/native video; software-debug captures fall below30fps |
| Accessibility |7.0|48dp controls/real-font/text-scale tests; native assistive-tech and full localization pending |
| Performance |4.0| No representative physical profile p50/p95/p99/memory/battery measurements |
| CI/CD |8.0| Pinned actions, real platform builds, artifacts and deterministic simulations; retained iPhone timeout flake |
| Android readiness |7.5| Debug/profile/release/AAB build and installed emulator checks; physical/signing/store gates pending |
| iOS readiness |6.5| Simulator build/installed checks; physical iPhone/signing/device target pending |
| Online/security readiness |2.0| Draft shared-Dart authority/RFC only; hosted Auth/RLS/two-client abuse/race acceptance missing |
| Overall production readiness |5.5| Local foundation is usable; global online, physical performance/security/release gates remain |

Do not average these into a release approval. Production release remains NO-GO.
A no-known-advisories Pub result does not establish application/backend security.

## Implemented and verified in this program increment

- #100 checkout7 merge4ecd208, #99 cache6 merge5d0d755, #98 artifact7 mergef100a3f:
  reconciled current workflows and passed exact-head checks. Artifact upload7 /
  existing download4 byte-identical report round trip verified in46092530291.
- #108 merged1b115af8 after foundation46093807383, security46093807387,
  platform46093807396 and simulation46093807385.3000 primary +30 repeat matches,
  seeds20261128–20261227,15256 restorations and30512 rejection probes. No rules changed.
- #110's cache change integrated through fully green #108. Its independent
  platform46093676269 failed installed iPhone driver180s timeout after VM readiness;
  retained logs do not establish underlying cause. Do not relabel that run passing.
- #111 merged46c8bcb5 after foundation46094145625, security46094145574,
  platform46094145577, default Android checkpoint46094163884 and recording46094163891.
 513 local tests and17 recovery cases passed. Image retry preserves frame gating.
- RTL profile ordering fix has a failing-before regression and24 passing focused
  cases. It remains a separate review/CI gate; no Arabic release is implied.

## Actual recording evidence

[Four-size artifacts](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/46094163891)
come fromffa034d4ecbca926c8bfd42b3e4543547d9a4ab2, Android API33 emulator,
normal animation timing, native screenrecord, debug Skia software renderer.
Seeded rolls/staged capture/AI/victory fixtures reuse production UI/MatchSession.
The fixture explicitly opens the existing accessible selection alternative;
ordinary clustered pawn selection remains direct on the board.

Downloaded H264 videos fully decoded; contact sheets/representative dice, landing,
AI/capture/turn/victory frames inspected. Logical320/360/393/430 recordings last
56.332/49.567/52.822/55.055 seconds. Native393x873 encodes392x872 for even dimensions.
Average encoded cadence4.70/8.70/7.38/5.18fps includes idle holds.30fps capture target
is NOT met. It is not physical60fps evidence or a before/after performance benchmark.
Separate default-renderer checkpoint is not Flutter-software acceptance.

## Remaining ordered work and statuses

| Work | Status | Gate |
| --- | --- | --- |
| Baseline audit/PR classification/simulation | VERIFIED COMPLETE | Evidence above; historical PRs not blindly replayed |
| Board image retry | VERIFIED COMPLETE | Automated gates; final owner visuals separate |
| RTL fixed physical profile slots | IMPLEMENTED, AWAITING VERIFICATION | Combined exact-head CI/native checks before merge |
| #104 dependency update | BLOCKED | Solver requires newer Flutter; SDK migration must be separately validated |
| Native process-death/low-memory/long-session soak | NOT STARTED | Codec tests do not prove disk/process durability |
| Complete English/Hindi/Telugu localization, settings/help/privacy, richer results | NOT STARTED for remaining scope | Preserve approved UI/rules and use focused PRs |
| Physical Android/iPhone, GPU frame/memory/battery profiling | BLOCKED | No physical devices attached |
| Auth/private Classic staging/RLS/security/two-client recovery | BLOCKED for hosted verification | Supabase connector lists zero projects; drafts90/94 require reconciled design |
| Production signing/store/device distribution | BLOCKED | Credentials/owner release acceptance absent |
| Final owner visuals/9.5 approval | BLOCKED | Do not clear through tests or software recordings |

Cross-platform Android job builds an APK, not an installed-app check. Installed
Android proof comes from checkpoint/recording workflows. iOS simulator acceptance
is not physical iPhone acceptance. Snapshot codec tests are not real process death.
No online rooms/friends/messaging, economy, tournament or9.5 release is claimed.
