# Architecture

## Repository layout

```text
apps/mobile/
  assets/                 Runtime images and fonts
  lib/
    main.dart             Flutter entry point
    src/
      app.dart            MaterialApp, theme, root navigation
      features/
        home/             Home screen and navigation
        match/            Match screen and presentation
      game/
        domain/           Rules, player state, board geometry
        presentation/     Flutter-specific player styling
  test/                   Unit, geometry, asset, and widget tests

assets/images/
  board/                  Canonical board artwork
  branding/               App icon and brand artwork

docs/
  product/                Product requirements
  architecture/           Architecture and module boundaries
  game/                   Rules profile
  assets/                 Asset contract
  engineering/            Rendering, animation, development, QA
```

The current Flutter source lives under `apps/mobile`. Keep Flutter-specific code inside that app.

## Dependency direction

- Domain rules and board geometry must not depend on Flutter widgets.
- Presentation reads game state and sends user actions to the domain layer.
- Animation interpolates between authoritative game positions; it never decides whether a move is legal.
- Asset paths and visual calibration are documented and tested.
- Tests should exercise rules independently from widget rendering wherever possible.

## State flow

1. A player requests a dice roll.
2. The UI asks the game layer to roll a value.
3. The engine calculates legal pawn choices.
4. The player selects a legal pawn.
5. The engine returns the next immutable game state.
6. Presentation animates from the previous pawn position to the new authoritative position.
7. The UI displays the resulting turn, capture, extra turn, or winner.

## Current implementation note

The current code contains a deterministic `LudoGame` domain model and a `BoardGeometry` mapping. The match screen currently owns a random dice source and directly renders pawn overlays. As the UI grows, move dice generation behind an injectable interface and extract pawn/dice widgets and animation controllers from the match screen. Keep game state immutable.

## Rendering contract

The game artwork is a visual layer. Pawns, dice, selection states, and transient effects are separate Flutter-rendered layers above it. Do not bake changing game state into a static board image.


## Legacy repository boundary

The older `chandra0000/ludo-lovers` repository is reference-only. Current app code, game state, geometry, assets, and tests must live in this rebuild. See [legacy repository isolation and migration guardrails](legacy-repository-isolation.md) before porting any old behavior. Do not introduce a second engine or coordinate table to preserve compatibility with the old app.
