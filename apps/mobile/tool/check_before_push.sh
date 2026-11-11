#!/usr/bin/env bash
set -euo pipefail

# Run from anywhere inside the repository before pushing Flutter changes.
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/apps/mobile"

echo "Checking Dart formatting (non-mutating)..."
dart format --output=none --set-exit-if-changed lib test tool integration_test

echo "Running strict Flutter analysis..."
flutter analyze --fatal-infos

echo "Running unit and widget tests..."
flutter test --reporter expanded

echo "Local checks passed. Android APK builds are validated in GitHub Actions."
