# Engine audit and benchmark baseline

This harness measures the authoritative rebuild engine before optimization. It is a diagnostic tool, not a performance gate: CI must not fail on machine-dependent wall-clock thresholds.

## Run

From `apps/mobile`:

```bash
flutter pub get
dart run tool/engine_benchmark.dart
```

Optional controls:

```bash
dart run tool/engine_benchmark.dart --warmup=2000 --samples=40 --iterations-per-sample=1000
```

The command writes one JSON document to stdout. Preserve the complete output as a CI artifact or attach it to the engine-audit issue when recording a baseline.

## Workloads

- Initial immutable state creation.
- Legal action enumeration after a six.
- Single-pawn move evaluation.
- Immutable transition and event generation.
- Capture transition and event generation.
- Snapshot JSON encode/decode.
- Seeded AI pawn selection using the authoritative legal-action API.

## Interpretation

Each workload performs warm-up operations, then measures batches and reports median and p95 microseconds per operation. Results include OS/runtime metadata and the exact warm-up, sample, and batch counts. Compare results only when device/runner, runtime, build mode, workload, and iteration settings match. For device performance, run in profile mode on the same physical Android device and record its model, Android version, app commit, and power/thermal conditions.

Do not use these numbers as unit-test assertions. Profile hotspots first; optimize only after repeatable evidence identifies a bottleneck. This harness is intentionally dependency-free and does not change runtime gameplay behavior or the default rule profile.
