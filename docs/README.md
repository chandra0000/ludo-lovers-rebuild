# Ludo Lovers documentation

This folder is the project handbook. Start here when joining the project or resuming work after a break.

## Documents

- [Product specification](product/product-specification.md) — product goals, visual identity, scope, and acceptance criteria.
- [Architecture](architecture/architecture.md) — app layers, state flow, rendering, and module boundaries.
- [Legacy repository reconciliation](architecture/legacy-repository-isolation.md) — source-of-truth boundaries, rebuild gap audit, and conflict-prevention rules.
- [Legacy feature recovery plan](LEGACY_FEATURE_RECOVERY_PLAN.md) — prioritized feature inventory, target modules, acceptance tests, and migration sequence.
- [Ludo Lovers Classic rules v1.0](game/LUDO_LOVERS_CLASSIC_RULES_v1.md) — proposed player-facing four-player rulebook; pending artwork, owner, and device approval.
- [Engine behavior reference](game/game-rules.md) — compatibility profile behavior, engine contracts, and implementation gaps.
- [Artwork and assets](assets/artwork-and-assets.md) — canonical image paths, formats, sizing, and preservation rules.
- [Animation and rendering](engineering/animation-and-rendering.md) — how the board, pawns, dice, and effects are rendered.
- [Engine benchmarks](engineering/engine-benchmarks.md) — reproducible correctness/performance baseline procedure.
- [Match command/session boundary](engineering/match-session-boundary.md) — typed commands, actor/version checks, idempotency and deterministic replay.
- [Code and app quality review](quality/code-and-app-quality-review-2026-11-11.md) — current engineering strengths, release blockers and prioritized improvements.
- [Physical Android acceptance and performance](DEVICE_ACCEPTANCE_AND_PERFORMANCE.md) — device-only P0 visual/gameplay and P1 profiling protocol.
- [Development and testing](engineering/development-and-testing.md) — setup, commands, CI, and quality gates.
- [Project status](PROJECT_STATUS.md) — implemented work, known gaps, and next steps.
- [Decision log](DECISIONS.md) — durable technical/product decisions and their rationale.

## Documentation rule

Every material architecture, gameplay, asset, or workflow change must update the relevant document in the same pull request. Record unverified assumptions as pending; do not describe them as accepted facts.

## Current productionization evidence

See [the 2026-11-16 baseline, Phase 0 diagnosis, and dependency ledger](quality/productionization-2026-11-16.md). It distinguishes current verification from historical status and pending release gates.

## Premium Match V2 checkpoint

Start with the [2026-11-18 release evidence](quality/premium-v2-release-readiness-2026-11-18.md)
for current exact source SHAs, workflow/artifact receipts, provisional scores and
open gates. The [execution ledger](quality/premium-v2-program.md) contains approved
local-mode decisions and the audit against actual legacy source.
[Quick v1](game/QUICK_RULES_v1.md) and [Team Up v1](game/TEAM_UP_RULES_v1.md) are
implemented internal previews; public availability requires separate acceptance.
The [online/private-room RFC](architecture/online-classic-private-rooms-rfc.md)
is awaiting architecture acceptance, not shipped online functionality. Older
evidence documents retain historical status and must not override this checkpoint.

## Royal unified gameplay checkpoint

The owner's final corner-profile direction supersedes the top-only V2 HUD. Read
[the royal execution ledger](quality/royal-unified-program-2026-11-18.md) and
[current royal release evidence](quality/royal-release-readiness-2026-11-18.md).
The approved board, logo, geometry, rules and turn order remain unchanged. Native
installed-app screenshots, software captures and physical-device acceptance are
distinct evidence classes. No review-stack PR is automatically merged.


## Responsive profile refinement

The [2026-11-19 composition update](quality/responsive-profile-composition-2026-11-19.md)
implements the owner's larger responsive avatars, logo between the top profiles,
smaller social icons and richer static backdrop. The board and engine remain unchanged.
