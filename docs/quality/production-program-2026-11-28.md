# Production program: verified baseline and integration order

Implementation baseline:c642a19c917f1020c8a57a72cdb724099b7c40ab.
Flutter3.35.7/Dart3.9.2. No AGENTS.md found in the repository/workspace parents.
The accepted post95 UI and forward-only policy remain authoritative.9.5/10 is a
product target, not an achieved score. Board/logo/geometry/rule profiles unchanged.

## Baseline and source reconciliation

Fresh strict203-file format, fatal-info analysis and496 tests PASS. Earlier
current-main receipts and the preferred UI are documented in
[current-main review](current-main-selective-review-2026-11-27.md). Native CI must
be read for each exact reviewed head; no physical-device acceptance is inferred.
Architecture/testing/post95 policy and existing online RFC were read. The legacy
reference was fetched at ee7a4fe2ffcdde93f2945df345acec08e8f87a5f. Its game-rules
and TeamUp engine are reference only. Historical PROJECT_STATUS/legacy backlog
entries describe old milestones; they do not override current working code.

## PR classification

| PR | Classification | Evidence/decision |
| --- | --- | --- |
|80 first-frame readiness | Already implemented | Current Image.frameBuilder reveals overlays only with decoded artwork; delayed-image test and guarded input exist |
|81 victory/rematch QA | Already implemented for core behavior | Current recording fixture legally reaches victory, restarts and verifies persisted profiles/state; retain historical evidence rather than replay branch |
|82 pawn targets | Superseded for implementation | Current effective48dp targets and post95 nearest/direct selection preserve purpose; do not restore chooser |
|84 loading message | Already implemented | Current board shows Preparing the board until first frame; failure is visible but recoverable retry is a remaining gap |
|85 active action header | Already implemented | Current MatchScreen/header show authoritative active identity/action; preserve latest implementation |
|88 provisioned iPhone | Superseded for original blocker | Current isolated simulator/VM-host script has bounded stages and passing installed acceptance; do not replace it wholesale |
|90 online intents | Requires forward-porting | Useful versioned intention decoder; needs joint envelope/idempotency/auth review with94; no production service |
|94 Supabase authority | Requires redesign/forward-porting | Shared Dart engine is useful; hosted SQL/RLS/reconnect acceptance, deadlines and rate/concurrency limits absent; fees/wallets excluded from initial private Classic scope |
|98 upload-artifact7 | Requires forward-porting | Reconcile current workflows and verify archive/download interoperability and artifact presence on exact head |
|99 cache6 | Requires forward-porting | Reconcile current workflows; correct stale version comments; verify hosted runner/cache behavior |
|100 checkout7 | Already implemented after review | Reconciled current main, upstream tag SHA verified,7 pinned uses only; no app changes; fresh CI required |
|104 grouped Pub | Blocked | Pinned Flutter3.35.7 cannot resolve proposed dependencies; actual solver rejects audioplayers>=6.8.0 requiring Flutter>=3.44 |
|39 renderer benchmark | Requires forward-porting | Current comparable isolated workload and physical traces needed; no renderer migration approved |
|40/42 halos/pawns | Already implemented for core behavior | Current exterior halo, glass pawn renderer and post105 identity/dimension protection; inspect unique patches before any closure |

Do not close historical PRs from this table alone. No obsolete branch is merged
for its title. Required order: verify100→merge→refresh99→verify/merge→refresh98→
verify/merge. Each child includes the validated new main; no force push.104 stays
blocked rather than silently upgrading the Flutter SDK. Engine simulation is an
independent tool/workflow change; new native/visual fixes remain separate PRs.

## Reproducible full-match verification implemented

Run from apps/mobile:

```sh
dart run tool/production_gameplay_simulation.dart --samples=100
```

The runner uses MatchSession for every accepted roll/move/pass, all four current
profiles, canonical local rosters and Easy/Medium/Hard.30 configurations ×100
seeds20261128–20261227 =3000 completed matches, plus30 exact seeded final-snapshot
replays. It checks version/receipt/roster/pawn bounds, ordered events within each
transition, snapshot round trips and duplicate/stale rejection. Event sequence is
transition-local; the harness preserves that existing contract rather than
imposing a new global sequence rule. No dice/rule/AI policy is changed.

[Executed report](evidence/production-simulation-2026-11-28.json) records actual
source commit, application-lib tree, runner blob, SDK/host and per-case seeds.
Actual primary-match counters:15256 snapshot restorations,30512 rejected command
probes. Counts exclude additional replay work, which is reported separately.
A one-roll cap exits1 and writes a failed report, not a passing incomplete result.
The dedicated workflow runs the full suite and verifies this failure path;
partial reports identify the failing case and remain artifacts.

These are host engine tests. Snapshot codec recovery is not native process-death,
atomic disk durability, rendering performance or multiplayer acceptance. No FPS,
physical-device or9.5/10 claim is made.

## Legacy parity and remaining ordered work

Verified legacy code contains Classic/local and TeamUp policies/tests. A string
such as Quick guide is not evidence of a legacy Quick mode. Rebuild current code
already supports versioned Classic/Quick/current local2/3/4, TeamUp4, seeded AI,
editable Unicode names, preferences, resume, local reactions and rematch. No
working legacy online rooms/friends/tournaments were established by this bounded
inventory; do not migrate README visions as services.

Remaining local gaps: board-asset retry, final winner presentation/localization,
complete settings/help/privacy and English/Hindi/Telugu flows; native screen-reader,
process-death/low-memory/long-match soak and physical profile traces. Preserve
approved normal UI while closing focused gaps. Physical hardware, signing/store,
translation/visual acceptance and hosted credentials remain separate gates.

Online RFC remains the design baseline: private Classic2/4 first, Supabase Auth
and scoped Postgres/Realtime plus an external trusted Dart authority. Edge relay
must not become a second rules engine. No schema deployment, coin economy,
authentication completion or online availability is claimed by this increment.

## Validated workflow integration receipt

PR100 merged at4ecd208d45d0698322955eef9f0d60202a9a8cc5 after exact head
36ed1bac889589ec94099512b49ac3ae803957f9 passed foundation46089331553,
Android/iOS46089331533 and dependency security46089331586. Application files
were unchanged. PR99 is refreshed on that baseline and awaits its own checks.
The local simulation receipt's sourceCommit is the local merge checkout; its
applicationLibTree equals this validated baseline and its runnerBlob exactly
matches the committed runner. Dedicated CI reruns the published revision and
uploads an independent exact-checkout receipt.

## Refreshed integration and diagnosed CI failure

PR99 merged at5d0d755803cf90bcbfa09552454fa0e1c03e5620 after foundation
46090758739, security46090758723 and default-renderer checkpoint46091299727
passed on95af1eac50db8dec98d82bb5ef2e7ac1e7f60abe. PR98 merged at
f100a3f17708fddcf1c0c9ac567c2e26345d49f5 after foundation46092530280,
platform46092530267 and security46092530291 passed. Security also proved a
byte-identical upload7/download4 advisory-report round trip.

The first simulation CI head22224c3 passed the full3030-match workflow46091190316,
foundation46091190277 and security46091190303, but Android debug job140812214751
failed before compilation on Maven HTTP429 for Kotlin dependencies. That failure
is preserved, not relabeled as success. PR110 adds the missing Gradle cache to
cross-platform Android using the existing pinned paths/key. Refreshed simulation
work includes that mitigation and current merged action versions; require fresh
exact-head CI before merge. PR110 must be merged first.

Cross-platform Android builds a debug APK; it is not an installed Android test.
Installed Android evidence comes from the checkpoint/recording workflow. macOS
includes installed iPhone simulator navigation. No emulator evidence is physical.
The Supabase connector currently lists zero projects, so hosted Auth/SQL/RLS and
two-client staging acceptance are blocked; no production credentials are present.
