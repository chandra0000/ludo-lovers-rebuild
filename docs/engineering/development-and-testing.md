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
flutter drive --no-pub --driver=test_driver/native_capture_driver.dart --target=integration_test/app_navigation_test.dart --dart-define=LUDO_ENABLE_UNRELEASED_MODES=true -d emulator-5554
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

The royal increment expands the complete suite to 445 passing tests. Foundation CI enforces strict
format, fatal-info analysis, domain/widget/persistence/lifecycle/mode regressions
and 36 required responsive/flow/royal PNGs. Use
`python3 tool/verify_responsive_screenshots.py --premium-flows` to verify them.
Android builds debug, split profile/release APKs and validation-only AAB outputs.
The generated runner's debug signing key is not production signing.

The opt-in Android checkpoint label is `run-android-integration`. The cross-platform
macOS job compiles iOS and runs the installed app on an available iPhone simulator.
Three installed tests cover repeated compatibility navigation, true Classic
two-seat/Quick three-seat/Team Up four-seat start/roll/restart/exit/resume and the
computer/profile-social flow. The SDK extended driver saves eight installed-app
PNGs under test-artifacts/native; verify with
`python3 tool/verify_responsive_screenshots.py --native-directory test-artifacts/native`.
The shared scenario also runs as a widget regression; a widget pass alone does not
prove native execution. Preview mode flags are limited to native QA commands and internal profile APKs
(`ludo-internal-modes-profile-apks`); release APK/AAB and normal debug builds keep
the public availability gate. Simulator/emulator results are
never physical-device acceptance. See the current
[release report](../quality/premium-v2-release-readiness-2026-11-18.md) for exact
commits, runs, artifacts and unresolved signing/device/owner gates.

## Royal acceptance evidence

The existing Premium V2 report is historical. Current royal source/file manifests,
CI results, screenshot/artifact receipts and explicit limitations are recorded in
[the royal release report](../quality/royal-release-readiness-2026-11-18.md).
Installed screenshots are emulator/simulator evidence, not physical-device or
performance traces: Android screenshot surface conversion intentionally changes
the capture rendering path. Use the internal profile APKs on actual hardware for
measured build/raster frame times, memory, startup, image decode and rebuild analysis.


### Bounded installed iOS integration

From `apps/mobile` on a Mac with an available iPhone simulator runtime, run
`bash ../../.github/scripts/ios_simulator_integration.sh`. The Python launcher
creates its own simulator, bounds boot/build/install/launch/driver attach separately,
probes a dedicated ephemeral loopback Dart VM-service port, requires eight native PNGs,
and deletes only its simulator on teardown. The CI simulator launch disables service auth codes/publication only for that
loopback debug process; production/native builds retain their normal settings.
Diagnostic console/unified-log/runtime metadata
is saved at repository-root `simulator-diagnostics/`. CI uploads the normal
AppMain `.app` before building the integration target, so the normal bundle and
installed test-harness evidence stay distinct. Do not increase timeouts or blindly
rerun a failed job: use its `IOS STAGE` output to identify the failed operation.
