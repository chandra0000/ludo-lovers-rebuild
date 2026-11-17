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
        domain/           Pure rules, geometry, AI and saved-match DTO
        application/      Authoritative MatchSession command boundary
        infrastructure/   SharedPreferences storage adapter
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

## Current implementation note — 2026-11-16

`MatchSession` owns accepted roll/move/pass transitions over immutable `LudoGame`.
`MatchCommandController` dispatches commands; dedicated turn, AI, animation and
persistence controllers coordinate presentation without duplicating rules.
Human dice remain injectable, seeded local randomness is preserved, and AI chooses
only engine-legal moves. No rule-profile defaults change in this work.

The pure `SavedMatch` DTO and codec live in `game/domain/persistence/saved_match.dart`.
`game/infrastructure/persistence/saved_match_store.dart` owns SharedPreferences I/O.
The snapshot constructor copies AI seats into an unmodifiable set so queued writes
capture the original metadata. Storage key, JSON schemas and migration behavior
are unchanged. Internal consumers now import the DTO and adapter explicitly.

`engine_architecture_boundary_test.dart` enforces that domain/application imports
stay in their permitted layers and use no Flutter, Flame, storage or other package
dependencies. Application may depend on domain; domain cannot depend on application.

On restoration, every pending accepted dice result is resolved for presentation,
including human seats. A human roll with no legal pawn schedules the ordinary
engine-validated pass; a single legal pawn follows the existing delayed automatic
move. No new roll is generated. Restored animation progress is not replayed.

The 576×1024 design canvas retains one uniform transform. Actual four-viewport PNGs
and native halo transparency tests protect rendering; visual and physical-device
acceptance remain separate gates.

## Rendering contract

The game artwork is a visual layer. Pawns, dice, selection states, and transient effects are separate Flutter-rendered layers above it. Do not bake changing game state into a static board image.


## Legacy repository boundary

The older `chandra0000/ludo-lovers` repository is reference-only. Current app code, game state, geometry, assets, and tests must live in this rebuild. See [legacy repository isolation and migration guardrails](legacy-repository-isolation.md) before porting any old behavior. Do not introduce a second engine or coordinate table to preserve compatibility with the old app.

## Premium V2 presentation ownership

`MatchTurnCoordinator` coordinates command dispatch, engine-legal automatic
selection and AI scheduling. It never calculates movement/capture/victory rules.
MatchScreen owns route/lifecycle integration and passes accepted events to the
animation lifecycle. Accepted command persistence has one serialized entry point.
`MatchPawnLayer`, `MatchDestinationPreview` and `MatchResultPresentation` are
read-only render/action surfaces. They do not own sessions, clocks or storage.
