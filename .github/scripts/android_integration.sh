#!/usr/bin/env bash
set -euo pipefail

# android-emulator-runner invokes its script through /bin/sh. Enter Bash
# explicitly from the workflow before enabling Bash's pipefail option.
adb devices -l
adb -s emulator-5554 shell getprop sys.boot_completed
flutter test integration_test/app_navigation_test.dart --timeout 3m --reporter expanded -d emulator-5554
