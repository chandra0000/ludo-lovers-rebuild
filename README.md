# Ludo Lovers — Rebuild

A clean, Android-first Flutter implementation of Ludo Lovers.

## First milestone

Deliver one reliable local four-player match with a stable first frame, faithful board artwork rendering, deterministic pawn coordinates, animated game pieces, and automated rule/UI tests. Additional modes and online services are out of scope until this foundation is accepted.

## Product constraints

- Preserve the approved black-and-gold premium glassmorphism identity.
- Preserve the original board artwork without cropping or distortion.
- Player colours: Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`.
- Turn order: Orange → Green → Magenta → Blue.
- Render pawns, dice, and effects programmatically; separate pawn/dice image uploads are not required.
- Keep game rules and board geometry independent from Flutter widgets.
- Never mark device acceptance complete without a real Android device test.

## Documentation

The project handbook is in [docs/README.md](docs/README.md). It covers product requirements, architecture, rules, artwork, animation, development, testing, status, and decisions. Update documentation in the same change as any material implementation or product decision.

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
