# Product specification

## Product

**Name:** Ludo Lovers  
**Tagline:** Play • Connect • Love  
**Platform priority:** Android first  
**Initial delivery:** One stable, complete, offline local match for four players.

## Visual identity

- Premium black-and-gold glassmorphism.
- Background: near-black.
- Gold accent: `#FFC857`.
- Orange player: `#FF8928`.
- Green player: `#33FF28`.
- Blue player: `#289EFF`.
- Magenta player: `#F428FF`.
- Turn order: Orange → Green → Magenta → Blue.

Do not redesign or reinterpret user-approved branding or board artwork without explicit approval.

## Initial milestone scope

Included:
- Home screen and local-match navigation.
- Four-player local game.
- Four pawns per player.
- Dice input and turn progression.
- Pawn movement, safe cells, captures, home lanes, and winning.
- Animated pawn movement and dice roll.
- Responsive rendering on Android portrait screens.
- Automated domain, geometry, asset, and widget tests.

Not included until the first milestone is accepted:
- Online multiplayer, accounts, matchmaking, chat, payments, ads, leaderboards, or additional game modes.

## Product acceptance

1. The app launches without a blank/black screen.
2. The supplied board artwork is shown in its original aspect ratio, without cropping or distortion.
3. Pawn centers align with the actual board cells and yards.
4. Dice results and legal moves are controlled by the game engine, not by animation code.
5. A complete local match can be played to a winner and restarted.
6. Touch targets are usable on a real Android phone.
7. Automated checks pass and a real-device smoke test is recorded separately.
