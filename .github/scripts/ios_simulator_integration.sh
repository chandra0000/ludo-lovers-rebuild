#!/usr/bin/env bash
set -euo pipefail
# Separate bounded deployment stages preserve logs before any integration test.
python3 ../../.github/scripts/ios_simulator_integration.py
