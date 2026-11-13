# Flutter vs Flame rendering experiment — 2026-11-13

Status: **experimental; no renderer migration approved**.

## Scope
This branch adds an opt-in `RendererBenchmarkScreen` and a geometry contract test. The screen is intentionally **not linked from Home** or `MatchScreen`, so it cannot change normal gameplay. It compares the existing Flutter `MatchBoardArtwork` widget with a Flame `SpriteComponent` using the same `board_exact.webp` derived crop and the same 52 `BoardGeometry.trackPosition` markers.

The canonical original `apps/mobile/assets/images/board/ludo_board_glass.webp` (810x1440) is **not modified**. The existing derived crop uses 864x1536 placement coordinates; this experiment does **not** resolve source-artwork parity or claim the derived crop is approved.

The authoritative `MatchSession`, rules, turn sequence, dice decisions, and geometry are untouched.

## How to run
`RendererBenchmarkScreen` is deliberately not exposed in production navigation. For a temporary local/profile experiment, navigate to `const RendererBenchmarkScreen()` from a developer-only route, then remove that route. Do not enable the route in production builds.

Run `flutter analyze --fatal-infos` and `flutter test` in `apps/mobile`. Build and run a **profile** APK on a physical Android phone, not a debug emulator. For each renderer, warm up, then capture at least 600 frame samples; repeat three runs, with the same phone, screen brightness, power mode, and viewport. Capture Flutter DevTools CPU/GPU frame timings, peak process RAM, image cache, startup-to-first-board, and battery impact. The in-screen p95 reports total frame timing and is only a convenience indicator; use DevTools trace exports for the actual decision.

## Crucial limitations
- This first experiment measures **static board + 52 diagnostic markers**. It does not yet compare moving pawns, dice, captures, stacked pawns, taps, semantics, image decode spikes, or full match-screen overhead.
- The 52 markers are not 52 actual pawns. Real Ludo matches have 16 pawns.
- A flame scene's fixed-resolution viewport must be checked against Flutter's fitted canvas on the same device before comparing geometry.
- Static-scene results **cannot** justify replacing the production renderer.
- Do not interpret green CI as a measured FPS or physical-device sign-off.

## Follow-up required before a final decision
1. Add the same scripted, deterministic **16-pawn** positions and timed movement sequence to both paths using accepted `MatchSession` events; preserve the existing event projection.
2. Record p50/p95/p99 UI and raster frame times, CPU, memory, startup and asset decoding for both paths, including repeated enter/exit.
3. Verify every anchor against the approved original source, especially diagonal connectors, yards, lanes, finish and stack hit targets.
4. Verify no regressions to TalkBack, reduced-motion, touch targets, or lifecycle.
5. Prefer existing Flutter renderer if both meet targets; migrate only a bounded rendering layer if Flame has a repeatable, meaningful benefit without regressions.

## Exit gate
No engine rewrite; no Flame migration; no production navigation until benchmark results and owner-approved board screenshots are reviewed. This PR should remain **draft** until static harness compiles, CI passes, and the dynamic-pawn comparison is implemented.
