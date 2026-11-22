# Development and testing

## Prerequisites

- Flutter 3.35.7 / Dart 3.9.2 for reproducible CI (pubspec lower bound is broader).
- Dart SDK compatible with the declared Flutter version.
- Android SDK and an Android device or emulator for runtime validation.

## Commands

Run from `apps/mobile`:

```bash
flutter --version
flutter pub get
dart format lib test integration_test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter test integration_test/app_navigation_test.dart --dart-define=LUDO_ENABLE_UNRELEASED_MODES=true -d emulator-5554
flutter create --platforms=android --project-name=ludo_lovers --org=com.ludolovers .
flutter build apk --debug
flutter run
```

## Automated checks

CI resolves dependencies, formats and analyzes application plus integration-test sources, runs unit/widget tests, captures the match canvas, generates Android project files, boots an API 33 x86_64 emulator for the repeated-navigation integration smoke test, builds debug and split release APKs, and uploads the outputs.

A green CI run is not equivalent to physical-device acceptance. Follow [the four-phase gameplay verification checklist](../quality/four-phase-gameplay-verification.md) and record physical-device evidence separately.

## Required test coverage

- Turn order and immutable state transitions.
- Dice bounds and legal pawn selection.
- Yard release, shared track, home lane, exact finish.
- Safe cells, capture, extra turns, winner detection.
- Geometry uniqueness, bounds, and all seat mappings.
- Board and icon asset existence and integrity.
- Home screen first frame and navigation.
- Dice and pawn interactions, match restart, and no accidental double input.
- Responsive layout and overflow checks.

## Device smoke test record

For each device test, record:
- Device model and Android version.
- App version / commit SHA.
- Screen size and orientation.
- Launch, home-to-match navigation, dice roll, pawn movement, capture, and restart outcomes.
- Any crash, jank, overflow, touch alignment, or visual mismatch.

Never mark device validation complete based only on emulator/CI output.

## Phase 4 stress and integration checks

The domain suite includes a deterministic 2,500-transition stress run. It verifies that every accepted command advances the state version once, command IDs remain unique, each snapshot retains exactly four players with four valid pawn positions each, and emitted events retain contiguous sequence numbers and the resulting state version. Separate tests ensure published state collections cannot be mutated.

The Android integration smoke test repeats home → local match → home navigation three times on an API 33 x86_64 emulator. It is intended to catch app boot, asset loading, navigation, and repeated screen lifecycle regressions; it is not a substitute for a physical-device gameplay test.

## Premium V2 automated gates

The complete suite currently has 414 passing tests. Foundation CI enforces strict
format, fatal-info analysis, domain/widget/persistence/lifecycle/mode regressions
and 29 required responsive/flow PNGs. Use
`python3 tool/verify_responsive_screenshots.py --premium-flows` to verify them.
Android builds debug, split profile/release APKs and validation-only AAB outputs.
The generated runner's debug signing key is not production signing.

The opt-in Android checkpoint label is `run-android-integration`. The cross-platform
macOS job compiles iOS and runs the installed app on an available iPhone simulator.
Both installed tests cover repeated compatibility navigation and true Classic
two-seat/Quick three-seat/Team Up four-seat start, roll, restart, exit and resume.
The shared scenario also runs as a widget regression; a widget pass alone does not
prove native execution. Preview mode flags are limited to QA commands; uploaded
normal builds keep the public availability gate. Simulator/emulator results are
never physical-device acceptance. See the current
[release report](../quality/premium-v2-release-readiness-2026-11-18.md) for exact
commits, runs, artifacts and unresolved signing/device/owner gates.
