# Post-PR-95 integration policy

Baseline: `c2305a0ed511b61da628a9ab4238054384045695` (merged PR #95).

Start every new change from current main. Historical PRs are references, not merge targets. Preserve board assets, authoritative geometry, MatchSession, player identities, local modes, direct pawn selection, 48 dp targets, persistence and native acceptance.

## Ordered delivery

1. Baseline regression protection: strengthen pawn identity and dimension tests; retain existing gameplay and board pixel tests.
2. Artwork and presentation: compare original and runtime board assets offline before proposing any change. PR #29 uses provisional clip coordinates and is not approved for production. PRs #40 and #42 have core improvements already present; audit remaining differences without restoring chooser UI.
3. Performance: fresh isolated Flutter/Flame benchmark, identical animated workload, physical profile-mode traces. PR #39 is reference only; no renderer migration without evidence.
4. Native stability: audit #78/#88 against current scripts, collect physical Android/iOS acceptance.
5. Online: audit #90/#94, then implement authenticated, transactional, idempotent server-authoritative rooms in focused PRs; staging and adversarial tests before release.
6. Social features, economy, localization and release readiness follow validated online foundations.

## Merge gates

Review exact diff against latest main; no unrelated reversions. Require strict format, fatal-info analysis, tests, Android profile/release, Android/iOS acceptance, checkpoint and four-viewport recordings for gameplay changes. Record exact head and evidence. Physical device quality is a separate release gate. Owner approval before merge. Do not close historical PRs until unique changes are accounted for.
