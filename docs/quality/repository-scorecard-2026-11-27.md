# Repository quality, security and competitive readiness

Assessment baseline: `main` at `1bc591318b4801949c2f616e8ce13549bf0ee012`.
This is a source/test review with actual Flutter widget captures, not a physical
device assessment, penetration test or live benchmark of Ludo King. Scores are
provisional reviewer judgments, not measured percentages or owner visual approval.
Unmerged PR implementations do not raise the current-main scores.

**Overall engineering/product foundation:6.0/10. Production readiness:3.5/10.**
The deterministic local engine is the strongest part. The game is not yet ready
to compete across reliability, polish, online services and device performance.

## Individual scores

| Area | Current main /10 | Evidence and limiting gap |
| --- | --- | --- |
| Architecture | 8.0 | Pure authoritative MatchSession, immutable/versioned commands and presentation extraction; large screen orchestration and integration queue remain |
| Engine determinism | 8.5 | Seeded rules/AI, idempotency/stale checks, typed events, full-match/stress regressions; physical lifecycle acceptance remains open |
| Gameplay correctness | 8.0 | Captures, safe cells, finishing, mode isolation and Team-Up regression suite; installed acceptance does not pass every required runtime |
| Local modes | 6.5 | Classic/Quick/Team-Up code and tests exist; distinguish internal QA previews from public availability, and verify each final integrated revision |
| UI/UX | 6.0 | Original approved board, royal background, centered logo and adaptive profiles; visibly tiny/redundant status on main, typography/startup polish still in #76 |
| Board fidelity | 8.5 | Central geometry, artwork/pixel/anchor regressions pass; no physical acceptance or final owner sign-off |
| Animation/feedback | 6.0 | Real event-driven dice/pawn movement exists; review cube seams/selection/capture polish at actual scale and default renderer |
| Accessibility | 5.5 | Automated targets/semantics and responsive checks exist; compact status is small, full TalkBack/VoiceOver and enlarged native text acceptance missing |
| Performance readiness | 3.0 | Evidence-readiness score, NOT an FPS estimate: no representative physical profile traces, unresolved default-renderer emulator loss |
| CI/release engineering | 6.0 | Strict formatting/analyzer, broad tests, builds and artifacts; failed installed gates and conflicted stacked PRs prevent a stable integrated release |
| Security assurance | 5.5 | Local-first scope, no known Pub advisories in current scan; mutable actions/no update automation on main, no full history/native/SDK security audit |
| Android readiness | 4.0 | Build/software evidence exists; latest #74 default checkpoint fails and required screenshots missing; signing/physical acceptance open |
| iOS readiness | 5.0 | Simulator build/evidence exists at historical revisions; final integrated installation/runtime and physical-device gates remain incomplete |
| Online/social services | 1.0 | Local chat/reactions are real; draft protocol/backend work is not a released authenticated multiplayer/friends service |
| Documentation | 7.0 | Extensive contracts/evidence; historical snapshots must not be confused with current source, several release claims need integration refresh |

The scores reflect a release-oriented review. They do not compare unmeasured
latency/FPS or proprietary artwork with a competitor. Do not advertise9/10 or
production-ready from automated task completion.

## Confirmed findings and implementation

| Priority | Finding | Action / status |
| --- | --- | --- |
| P0 release gate | #74 exact headf508388 loses installed Android driver/device; required screenshots fail | BLOCKED: [run45861856889](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45861856889); underlying native trigger unproven. No blind retry/timeout increase |
| P1 reliability | SavedMatchStore ignores native setString=false, so controller/exit flow can claim durable success | Reproduced with failing native-channel regression; isolated fix on fix/persistence-write-failure. Requires its own tests/build review; not merged |
| P2 supply chain | Main workflows reference mutable third-party tags and retain checkout credentials unnecessarily | IMPLEMENTED on fix/repository-security-quality-audit:31 action uses pinned to upstream-verified SHAs, persist-credentials=false, existing read-only permissions preserved |
| P2 maintenance | No recurring dependency advisory/update gate | IMPLEMENTED: weekly Dependabot Pub/action updates, bounded OSV workflow, exact locked versions, immutable-action guard and fail-closed regression tests; no automatic merge |
| P1 draft-online deployment | #94 HTTP body reads and upstream response joins have byte/connect limits but no overall read deadline; no general request rate/concurrency gate | Static review finding, not a demonstrated live exploit. BLOCK online deployment pending authority choice and malicious/slow-client/load tests |
| P1 architecture/product | #90 adapter and #94 server/database represent different online maturity/authority scope; #94 also introduces wallets/fees/pot | Joint architecture and explicit product/economy decision still required. No deployment/schema mutation or authority choice made |
| P1 accessibility/UX | Main status text is small and duplicates action/identity; chooser/typography and native branding work remain unintegrated | Review #76 after #74/#75 with fresh100%/200% native evidence; do not duplicate its implementation |
| P1 acceptance | Process death, low-memory/long-match soak, physical performance, native screen readers and owner visual approval lack final evidence | BLOCKED, separate release gates; mock saved preferences/widget captures do not satisfy them |

Mutable action tags are a preventive supply-chain finding, not evidence of a
compromised action. Saved preferences are local game data, not an authentication
or wallet boundary. No critical exploitable vulnerability in current main was
established by this bounded review; that is not a guarantee of absence.

## Security scope and receipts

- Public OSV query on2026-11-27 checked44 resolved hosted Pub package versions:
  **no known advisories returned**. Scanner explicitly excludes root/Flutter SDK
  packages. Native Android/iOS toolchains, Flutter engine, undisclosed CVEs and
  runtime authorization are not covered.18 newer compatible/incompatible package
  releases were reported by pub; outdated is not synonymous with vulnerable.
- Current-tree high-confidence markers for private keys, GitHub tokens and AWS
  access keys: no matches in tracked files up to2MB. This is not an entropy-based,
  full-history, secret-provider or generated-artifact scan. No credentials printed.
- #94 RLS/grant code was inspected: public tables enable RLS, membership reads
  are scoped, commit RPC is revoked from public/anon/authenticated and granted to
  service_role. This is useful design evidence, not database execution/security
  acceptance. No live Supabase project or credentials were accessed.
- Current Supabase changelog and Data API security guidance were consulted.
- Action SHA receipts were resolved from GitHub's public commit API for the same
  v4/v2 tags already used: checkout, cache, upload-artifact, flutter-action and
  android-emulator-runner. No major action/Flutter/dependency upgrade is bundled.
- OSV failures/incomplete results or unsupported dependency sources fail the new
  check. An advisory finding exits1; transport/schema error exits2. No suppression
  allowlist is introduced. SDK coverage remains explicitly excluded in artifacts.

## Verification on this baseline

- Flutter3.35.7/Dart3.9.2; strict188-file formatting and fatal-info analysis PASS.
- Full current-main unit/widget/domain suite:446 tests PASS.
-36 required responsive/flow/royal captures verified, including320×640,360×800,
  393×873 and430×932. Fresh FFA and Team-Up screenshots inspected; widget evidence
  is not native installed evidence. Main's fonts are its current configured fonts;
  the locally bundled Cinzel/Nunito implementation remains in #76.
- Six advisory-handling tests plus four immutable-reference tests PASS. Workflow
  YAML,31 pinned uses, read-only permissions, nonpersistent checkouts and diff
  whitespace checks PASS. Real OSV endpoint exercised successfully.
- No new physical or default-GPU run, APK/AAB, iOS installation or current gameplay
  video is claimed here. Existing historical software recordings remain labeled
  by their actual source and cannot approve a new integrated revision.

Reproduce security checks from repository root:

```bash
python3 .github/scripts/test_audit_pub_dependencies.py
python3 .github/scripts/test_verify_workflow_security.py
python3 .github/scripts/verify_workflow_security.py
cd apps/mobile
flutter pub get --enforce-lockfile
dart pub deps --json > ../../dependency-graph.json
cd ../..
python3 .github/scripts/audit_pub_dependencies.py dependency-graph.json --output security-artifacts/pub-advisories.json
```

## PR work and correct integration

#54–#73 are merged. #74 targets main but is blocked by runtime failure; #75 has
an android-integration.yml conflict; #76 is draft. Continue #74→#75→#76 only
through reviewed passing revisions, then #80→#85→#86→#87→#89→#92. #86's later
dice fix already exists as an equivalent cherry-pick; do not apply it twice.
Review sidebars #81/#84/#88/#91 only for missing deltas. #93/#95 follow #92.
Keep #90/#94 draft for the authority decision. #39/#40/#42 contain historical
overlap and must not roll the current HUD/tests back. See refreshed audit PR#77.

#78 [comparison45017046727](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45017046727)
has default failures and software passes for both control/candidate. It separates
renderer evidence; it neither proves the native trigger nor clears production GPU.

The security hardening and persistence fixes are independent focused review
branches based on current main. Do not merge automatically. After they are
accepted, reconcile overlapping workflow edits in the stack and pin any newly
introduced actions; the guard intentionally rejects new mutable references.

## Competitive priorities

1. Establish a reliable default-renderer installed baseline and integrate reviewed
   work. Resolve conflicts and source-specific failures rather than accumulating
   more disconnected presentation branches.
2. Finish the already-approved premium typography/startup/status/selection work;
   inspect actual installed screens, full-motion dice/capture and200% text.
3. Collect midrange Android profile/release frame/raster/memory/startup traces,
   real lifecycle/process-death/long-match results and iPhone device acceptance.
4. Keep deterministic local modes understandable and reliable. Then select one
   secure online architecture with reconnect/load/moderation/privacy acceptance.
5. Build retention features through approved product decisions and measured play
   testing. Online depth, friends, tournaments and economy cannot be declared
   complete because protocol files, screens or SQL exist.

Aim for9/10 through measured acceptance, not more visual effects or a heavy engine
migration. Approved board/logo/colors, portrait layout, geometry and MatchSession
contracts remain unchanged by this work.
