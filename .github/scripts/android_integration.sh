#!/usr/bin/env bash
set -euo pipefail

# android-emulator-runner invokes its script through /bin/sh. Enter Bash
# explicitly from the workflow before enabling Bash's pipefail option.
adb devices -l
adb -s emulator-5554 shell getprop sys.boot_completed
# The workflow compiles this exact target before booting QEMU. Do not overlap
# Gradle/Kotlin compilation with the emulator's guest/graphics memory budget.
test -s build/app/outputs/flutter-apk/app-debug.apk
flutter drive --no-pub --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk --driver=test_driver/native_capture_driver.dart --target=integration_test/app_navigation_test.dart --dart-define=LUDO_ENABLE_UNRELEASED_MODES=true -d emulator-5554
python3 tool/verify_responsive_screenshots.py --native-directory test-artifacts/native
