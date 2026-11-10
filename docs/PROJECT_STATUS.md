# Project status

Last updated: 2026-11-10

## Repository

- Repository: [chandra0000/ludo-lovers-rebuild](https://github.com/chandra0000/ludo-lovers-rebuild)
- The folder-structure PR was merged as PR #2.
- Existing Flutter foundation work is present on branch `feat/flutter-foundation`.
- PR #1 was closed without merge; do not assume that its code is on `main`.
- This documentation update is being prepared on `feat/app-foundation-documentation`.

## Existing implementation found on the foundation branch

- Flutter app entry point, app theme, and home screen.
- Local match screen with programmatically drawn pawn tokens.
- Provisional deterministic game engine.
- 52-cell shared-track geometry and home-lane mapping.
- Unit, geometry, asset-integrity, and widget tests.
- Flutter CI workflow for analyze, tests, Android scaffold generation, and debug APK build.

## Not yet accepted / known gaps

- User's canonical board image and app icon need to be uploaded and verified at the documented paths.
- The current code references a full-screen concept/reference WebP, not yet verified as the final canonical board-only artwork.
- Current pawn positions are provisional and must be calibrated against the final supplied board image.
- Dice currently displays the result as a number in a circular overlay; a polished animated dice component is still required.
- Pawn movement currently changes state but does not yet animate step-by-step along the track.
- The game rule profile needs user acceptance (see [game rules](game/game-rules.md)).
- Real Android device testing has not been performed/recorded.

## Next implementation sequence

1. Confirm the two canonical assets are uploaded and inspect their dimensions and appearance.
2. Update Flutter asset declarations and launcher icon configuration.
3. Replace the provisional reference background with the canonical board image, preserving aspect ratio.
4. Calibrate every pawn yard, track, home-lane, and finish coordinate against that board.
5. Extract reusable pawn and dice widgets and add polished animations.
6. Complete game rules and interaction tests.
7. Run CI, build the APK, then perform a real-device smoke test.

## Completion policy

Only mark a task complete when the repository change and validation evidence exist. Keep assumptions and pending visual sign-off explicit.
