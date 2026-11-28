# Ludo Lovers — Rebuild

A clean, Android-first Flutter implementation of Ludo Lovers.

## Developing a local match feature

Start in `apps/mobile`. Classic, Quick, VS Computer and Team Up share the match presentation. Mode availability is controlled by the mode registry.

| When changing | Start here (relative to apps/mobile) | Verify |
|---|---|---|
| Shared route, home lanes or safe squares | `lib/src/game/domain/board_geometry.dart` | Board topology, pixel anchors and safe-cell tests |
| Legal moves, captures or turn order | `lib/src/game/domain/ludo_game.dart` and `team_up_policy.dart` | Rule profile tests, deterministic replay and saved-match recovery |
| Computer decisions | `lib/src/game/domain/ai/seeded_ludo_ai.dart` | Seeded choices against engine-legal moves |
| Player controls, dice and turn feedback | `lib/src/features/match/` and `lib/src/game/presentation/` | Widget tests, installed gameplay and reduced-motion checks |

Route player actions through `MatchSession`. Use the existing versioned rule profiles when opening saved games. Verify a release candidate on its commit using the [device acceptance and performance protocol](docs/DEVICE_ACCEPTANCE_AND_PERFORMANCE.md).

## Product constraints

- Preserve the approved black-and-gold premium glassmorphism identity.
- Preserve the original board artwork without cropping or distortion.
- Player colours: Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`.
- Turn order: Orange → Green → Magenta → Blue.
- Render pawns, dice, and effects programmatically; separate pawn/dice image uploads are not required.
- Keep game rules and board geometry independent from Flutter widgets.
- Never mark device acceptance complete without a real Android device test.

## Documentation

The project handbook is in [docs/README.md](docs/README.md). It covers product requirements, architecture, rules, artwork, animation, development, testing, status, and decisions. Update documentation in the same change as any material implementation or product decision. See [the 2026-11-10 competitive gap review](docs/competitive-gap-review-2026-11-10.md) for the rebuild-versus-legacy scorecard, glass-cone pawn/board-alignment validation limits, Ludo King benchmark, and prioritized product gaps.

## Local Android setup

Run from the repository root:

```bash
cd apps/mobile
flutter create --platforms=android --project-name=ludo_lovers --org=com.ludolovers .
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter run
```

Generate a debug APK with `flutter build apk --debug`.

## Artwork upload paths

- Board: `apps/mobile/assets/images/board/ludo_board_glass.webp`
- App icon: `apps/mobile/assets/images/branding/ludo_lovers_icon.webp`

These canonical user assets must be verified before visual calibration is accepted. Do not crop, stretch, recolor, or redesign them.

## Current status

The rebuild is maintained directly on `main`. The local four-player foundation, deterministic rules engine, animated dice/pawns, seeded local AI, and automated tests are implemented. Local match snapshots now preserve game state and AI seat configuration across app restarts, with a resume action on the home screen. Board geometry is still pending owner visual approval and physical-device QA. Routine CI checks formatting, analysis, tests, and split profile/release APKs; Android emulator integration is a separate major-change checkpoint. See [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md) for verified status and remaining gates.
