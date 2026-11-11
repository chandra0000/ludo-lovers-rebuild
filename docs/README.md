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
