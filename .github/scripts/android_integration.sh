#!/usr/bin/env bash
set -euo pipefail

# android-emulator-runner invokes its script through /bin/sh. Enter Bash
# explicitly from the workflow before enabling Bash's pipefail option.
adb devices -l
adb -s emulator-5554 shell getprop sys.boot_completed
# Capture diagnostics while the device is alive; post-failure ADB may be offline.
diag="../../emulator-diagnostics"
mkdir -p "$diag"
timeout 15s "$ANDROID_HOME/emulator/emulator" -version > "$diag/emulator-version.txt" 2>&1 || true
timeout 15s "$ANDROID_HOME/emulator/emulator" -help-gpu > "$diag/emulator-gpu-help.txt" 2>&1 || true
adb -s emulator-5554 logcat -v threadtime > "$diag/live-logcat.txt" 2>&1 &
logcat_pid=$!
cleanup_diagnostics() {
  kill "$logcat_pid" 2>/dev/null || true
  wait "$logcat_pid" 2>/dev/null || true
}
trap cleanup_diagnostics EXIT
# The workflow compiles this exact target before booting QEMU. Do not overlap
# Gradle/Kotlin compilation with the emulator's guest/graphics memory budget.
test -s build/app/outputs/flutter-apk/app-debug.apk
flutter drive --no-pub --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk --driver=test_driver/native_capture_driver.dart --target=integration_test/app_navigation_test.dart --dart-define=LUDO_ENABLE_UNRELEASED_MODES=true -d emulator-5554
python3 tool/verify_responsive_screenshots.py --native-directory test-artifacts/native
