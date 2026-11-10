# Development and testing

## Prerequisites

- Flutter stable (project currently declares Flutter >= 3.27.0).
- Dart SDK compatible with the declared Flutter version.
- Android SDK and an Android device or emulator for runtime validation.

## Commands

Run from `apps/mobile`:

```bash
flutter --version
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter create --platforms=android --project-name=ludo_lovers --org=com.ludolovers .
flutter build apk --debug
flutter run
```

## Automated checks

CI is configured to resolve dependencies, format, analyze, run tests, generate Android platform files, build a debug APK, and upload the APK artifact.

A green CI run is not equivalent to physical-device acceptance.

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
