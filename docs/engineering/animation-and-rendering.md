# Animation and rendering plan

## Principle

The board artwork is static. Dynamic game pieces are rendered by Flutter. The game engine owns positions and rules; animation only visualizes state changes.

## Pawn rendering

- Draw four player colours using the approved palette.
- Render classic cone-shaped pawns with a glossy translucent/glass-finish gradient, specular highlight, bright rim, elliptical foot, and soft ground shadow using `GlassyPawn` (`apps/mobile/lib/src/game/presentation/glassy_pawn.dart`). No separate pawn images or 3D models are required.
- Highlight every pawn belonging to the active player with a subtle colour-matched halo; apply a stronger gold highlight and slight scale-up only to legally movable pawns.
- When multiple players share one cell, arrange their pawns in a compact 2×2 formation and reduce their rendered size so each colour remains visible. Use one unambiguous stack hit target; if multiple legal pawns from the active player share the cell, show a chooser instead of relying on overlapping tap targets. Preserve semantic labels for every pawn.
- Animate pawn movement with a dedicated controller and interpolate through each intermediate board-cell center; the visual pawn follows the route cell-by-cell while the rules engine commits the legal destination state.
- Release-from-yard movement animates from the yard position to the player's entry cell. Capture feedback and finish celebrations remain planned.
- Add selection pulse/glow only for legal pawns.
- Add a short capture feedback effect and a distinct finish celebration.
- Ensure stacked pawns remain selectable and visually distinguishable.

## Dice rendering

- `AnimatedDice` paints a rounded gold die and 1–6 pips using Flutter canvas drawing.
- Animate the reveal with rotation, scale, and bounce; temporary faces are presentation-only and never affect the engine result.
- Display the engine's final value after the 720 ms reveal completes. Disable pawn input while the dice is animating and defer a no-legal-move turn pass until the reveal finishes.
- Disable repeat taps while a roll is in progress.
- Dice randomness must be injectable for deterministic tests.

## Coordinate system

- Calibrate the center of each yard position, shared-track cell, home-lane cell, and finish cell against the actual approved board asset.
- Store normalized coordinates so layout scales without changing the geometry.
- Convert normalized board coordinates to screen coordinates using the board image's displayed rectangle, not the entire screen.
- Add geometry tests for all four seats and visual regression evidence for representative cells.
- Never use guessed coordinates as accepted geometry.

## Performance and accessibility

- Prefer lightweight Flutter transforms and custom painting over per-frame image decoding.
- Keep animation controllers scoped to visible widgets and dispose them.
- Use stable keys and semantic labels for interactive pawns and dice.
- Test low-memory Android devices and avoid unnecessary large textures.
