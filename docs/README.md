# Ludo Lovers documentation

This folder is the project handbook. Start here when joining the project or resuming work after a break.

## Documents

- [Product specification](product/product-specification.md) — product goals, visual identity, scope, and acceptance criteria.
- [Architecture](architecture/architecture.md) — app layers, state flow, rendering, and module boundaries.
- [Legacy repository reconciliation](architecture/legacy-repository-isolation.md) — source-of-truth boundaries, rebuild gap audit, and conflict-prevention rules.
- [Legacy feature recovery plan](LEGACY_FEATURE_RECOVERY_PLAN.md) — prioritized feature inventory, target modules, acceptance tests, and migration sequence.
- [Game rules](game/game-rules.md) — current provisional rules profile and rule decisions requiring confirmation.
- [Artwork and assets](assets/artwork-and-assets.md) — canonical image paths, formats, sizing, and preservation rules.
- [Animation and rendering](engineering/animation-and-rendering.md) — how the board, pawns, dice, and effects are rendered.
- [Development and testing](engineering/development-and-testing.md) — setup, commands, CI, and quality gates.
- [Project status](PROJECT_STATUS.md) — implemented work, known gaps, and next steps.
- [Decision log](DECISIONS.md) — durable technical/product decisions and their rationale.

## Documentation rule

Every material architecture, gameplay, asset, or workflow change must update the relevant document in the same pull request. Record unverified assumptions as pending; do not describe them as accepted facts.
