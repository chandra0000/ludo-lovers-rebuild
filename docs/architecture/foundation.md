# Ludo Lovers foundation architecture

## Scope

The first milestone is one local, four-seat match. Online multiplayer, accounts, chat, payments, matchmaking, ads, and extra modes are intentionally excluded.

## Layers

- `game/domain`: deterministic game state and rules; no Flutter UI dependencies beyond the player colour token.
- `features/match`: presentation and input only.
- `features/home`: first-frame launch and navigation.
- `test`: rule and widget regression coverage.

## Product contract

- Palette: Orange #FF8928, Green #33FF28, Blue #289EFF, Magenta #F428FF.
- Turn order: Orange → Green → Magenta → Blue.
- Four pawns per player.
- No artwork is cropped or stretched.
- Device acceptance is separate from CI and must be recorded only after a physical Android test.

## Artwork status

The existing repository's `apps/mobile/assets/images/ludo_board_glass.webp` was inspected. It is a full-screen app concept image containing player portraits, labels, the board, dice, and navigation controls—not a standalone board texture. It must not be stretched into the board widget or treated as the calibrated board source. It is preserved separately as a design reference in this repository. The board-only source artwork and its exact cell-center calibration must be confirmed before pawns are overlaid on it.

## Known rule profile

The engine uses a 52-cell shared track, four pawns per player, progress -1 for home, and progress 56 for the finish. Safe track IDs are provisionally defined as 0, 8, 13, 21, 26, 34, 39, and 47. These rule constants require acceptance against the user's intended Ludo rules before release.
