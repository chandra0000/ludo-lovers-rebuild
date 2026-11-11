# Engine audit and benchmark baseline

This harness measures the authoritative rebuild engine on the Dart VM before optimization. It is a host-side microbenchmark, not an Android frame-time or GPU benchmark. It is a diagnostic tool, not a performance gate: CI must not fail on machine-dependent wall-clock thresholds.

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
- Single-pawn move evaluation, including an intermediate hard-blockade path check.
- Immutable transition and event generation.
- Capture transition and event generation.
- Snapshot JSON encode/decode.
- Seeded AI pawn selection using the authoritative legal-action API.

## Interpretation

Each workload performs warm-up operations, then measures batches and reports median and p95 microseconds per operation. Results include OS/runtime metadata, processor count, the explicit `dart-vm-jit` execution mode, and exact warm-up, sample, and batch counts. Compare results only when runner hardware, runtime, execution mode, workload, and iteration settings match. This script does not execute inside the Android app. For Android performance, install the CI profile APK on the same physical device, record model/Android/app commit and power/thermal conditions, and capture frame timing with Android Studio or Perfetto. Keep those device measurements separate from this host-side engine baseline.

Do not use these numbers as unit-test assertions. Profile hotspots first; optimize only after repeatable evidence identifies a bottleneck. This harness is intentionally dependency-free and does not change runtime gameplay behavior or the default rule profile.
