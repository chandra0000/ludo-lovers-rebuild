#!/usr/bin/env bash
set -euo pipefail

# CI runtime evidence is separate from the unsigned simulator build artifact.
SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
runtimes=json.load(sys.stdin)["devices"]
phones=[d for runtime,devices in runtimes.items() if "iOS" in runtime for d in devices if d.get("isAvailable") and d["name"].startswith("iPhone")]
if not phones: raise SystemExit("No available iPhone simulator runtime")
print(phones[0]["udid"])
')
export SIMULATOR_ID
if ! xcrun simctl list devices booted -j | python3 -c 'import json,os,sys; sys.exit(0 if any(d["udid"] == os.environ["SIMULATOR_ID"] for ds in json.load(sys.stdin)["devices"].values() for d in ds) else 1)'; then
  xcrun simctl boot "$SIMULATOR_ID"
fi
xcrun simctl bootstatus "$SIMULATOR_ID" -b
flutter drive --no-pub --driver=test_driver/native_capture_driver.dart --target=integration_test/app_navigation_test.dart \
  -d "$SIMULATOR_ID" --dart-define=LUDO_ENABLE_UNRELEASED_MODES=true
python3 tool/verify_responsive_screenshots.py --native-directory test-artifacts/native
