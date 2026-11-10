# Animation and rendering plan

## Principle

The board artwork is static. Dynamic game pieces are rendered by Flutter. The game engine owns positions and rules; animation only visualizes state changes.

## Pawn rendering

- Draw four player colours using the approved palette.
- Use a layered token style (body, highlight, rim/shadow) for a polished 3D-like appearance without requiring 3D models.
- Animate between cell-center coordinates with an animation controller.
- Move through intermediate cells for a multi-step roll rather than teleporting to the destination.
- Add selection pulse/glow only for legal pawns.
- Add a short capture feedback effect and a distinct finish celebration.
- Ensure stacked pawns remain selectable and visually distinguishable.

## Dice rendering

- Draw a rounded cube and pips from the current integer value (1–6).
- Animate a short roll with rotation, scale, and bounce.
- Display the engine's final value only after the roll completes.
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
