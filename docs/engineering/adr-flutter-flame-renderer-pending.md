# ADR: Flutter versus Flame board presentation

Status: **proposed / decision deferred** (2026-11-13)

## Decision boundary

Only the rendering and animation of the board and pawns is in scope.
`MatchSession`, immutable game state, accepted commands and events, dice,
rules, and all authoritative `BoardGeometry` coordinates remain independent
of either renderer. No renderer change is authorized by this ADR.

## Options

| Criterion | Flutter widget/custom-painter renderer | Flame component renderer |
| --- | --- | --- |
| Existing production integration | Already in use | Experimental only |
| Game rules authority | `MatchSession` | Must remain `MatchSession` |
| Board geometry | `BoardGeometry` | Must consume the same API |
| Animated pawn control | Flutter animation/controllers | Flame update/component loop |
| Accessibility/semantics | Native widget tooling | Requires explicit equivalent overlay |
| Complexity and integration risk | Lower migration risk | New lifecycle, input and overlay bridge |
| Frame time / memory / startup | **Unmeasured here** | **Unmeasured here** |

## Evidence currently available

- PR #39 contains a static prototype, not a representative moving-pawn
  benchmark. A 52-track-anchor contract test exists.
- Original workflow run `43430024664` failed strict Dart formatting before
  analysis, tests or APK jobs executed. It does not establish either renderer's
  runtime behavior.
- No profile-mode physical-device trace, screenshot acceptance run, startup
  trace, retained-memory trace, CPU trace, or repeated entry/exit measurement
  has been captured for this comparison.

## Decision criteria and required follow-up

1. Render the *same* approved board crop and glass-cone pawn artwork with 52
   track anchors, 20 lane anchors, 16 yard sockets and the exact finish anchor.
2. Drive 16 pawns from one immutable, event-ordered deterministic scenario;
   verify entry, six-step movement, diagonal artwork connectors, capture,
   stacking, lane, exact finish, and turn transition in both implementations.
3. Collect profile-mode UI and raster p50/p95/p99 distributions and startup,
   decode, peak/retained RAM, CPU and repeated lifecycle measurements.
4. Repeat on the same supported 6.1–6.9-inch phone at least three times per
   renderer, with matched settings, after warm-up; export raw samples and
   measurement metadata with a documented run command.
5. Reject any candidate that changes `MatchSession`, produces duplicate
   accepted events, changes approved board alignment, regresses accessibility,
   or introduces crash/black-screen risk.

**Current recommendation: keep the Flutter renderer in production.** This is
the conservative *interim status quo*, **not** a measured verdict against
Flame. Revisit only after both workloads are equivalent and independently
reproducible measurements show a meaningful benefit without regressions.

## Pending acceptance evidence

- [ ] Full Flutter / Flame 16-pawn animation parity
- [ ] Screenshot comparison against approved glass board and cone pawns
- [ ] Automated event-idempotency and single-animation tests for both views
- [ ] Profile and release Android builds
- [ ] p50/p95/p99 UI and raster timing JSON and Markdown reports
- [ ] Startup, asset decode, CPU, peak and retained RAM measurements
- [ ] Repeated enter/exit memory and lifecycle test
- [ ] Physical-device and reduced-motion/semantics acceptance

