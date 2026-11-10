# Four-phase gameplay verification

Last updated: 2026-11-10

This checklist separates automated correctness from artwork approval and physical-device acceptance. A green GitHub Actions run is evidence only for the checks that actually ran.

## Phase 1 — asset and render stability

Automated evidence:
- Canonical board and launcher assets are declared in the Flutter asset manifest.
- Home/match widget tests verify the app's first frame and required match controls.
- CI captures and uploads the 393×873 match-canvas screenshot.

Still required:
- Inspect the uploaded screenshot against the unchanged 810×1440 source artwork.
- Verify no crop, stretch, missing assets, or visual regression on a physical Android device.

## Phase 2 — board geometry

Automated evidence:
- Geometry tests cover the 52 unique shared-track cells, player-relative routes, five-cell home lanes, separate finish, safe-cell metadata, connector indexes, all 16 yard overlays, all 52 source-pixel route anchors, and all 20 source-pixel lane anchors.
- Responsive widget tests cover 360×800, 393×873, 412×915, and 800×360.

Still required:
- Measure grid bounds and all 16 yard socket centres from the original artwork.
- Compare route, entries, safe cells, home lanes, finish, and stack centres against the uploaded screenshot.
- Keep `BoardGeometry.visualApprovalPending` true until pixel comparison and owner review pass.

## Phase 3 — engine correctness

Automated evidence:
- Focused tests cover turn order, six-to-enter, legal movement, exact finish/overshoot, capture from all four seat orientations, every configured safe cell, single-pawn versus stacked-pair capture, winner detection, compatibility and opt-in Classic profile behaviour. Snapshot tests also verify profile-aware consecutive-six restoration and schema-v1 migration to schema v2.
- State-version guards, in-memory duplicate command IDs, typed ordered events, and immutable snapshots have regression coverage.
- A deterministic 2,500-transition stress test checks snapshot invariants and event sequencing.

Still required:
- Decide and document the product's accepted Classic rules, including own-pawn stacking, opponent blockades, safe-star identity and match-completion mode.
- Add durable serialization/replay and a complete command/result/error boundary before claiming parity with the legacy engine.

## Phase 4 — integration, stress, and device QA

Automated evidence added in this phase:
- Flutter integration test boots the app and repeats home → local match → home navigation three times on an Android emulator.
- Domain stress test runs up to 2,500 deterministic accepted transitions and checks four-player membership, pawn progress bounds, state-version increments, unique command IDs, and event sequence/version consistency.
- Snapshot immutability is tested for player lists, pawn progress, events, and command IDs.
- CI runs the integration smoke test on an Android API 35 x86_64 emulator, in addition to unit/widget tests and debug/release APK builds.

Physical-device acceptance remains open. On at least one real Android phone, record:
- Device model, Android version, app commit SHA, display resolution, refresh rate, and APK variant.
- Cold launch and repeated foreground/background/resume.
- Home → match → exit → match navigation, repeated at least five times.
- Dice input, yard release, normal movement, capture, safe-cell landing, no-legal-move pass, exact finish, and play-again.
- Touch target alignment and board artwork preservation in portrait; confirm landscape remains usable and does not crop the artwork.
- Any crash, Flutter exception, dropped frame/jank, memory pressure, overheating, or unexpected battery drain.
- Screenshot/video evidence and whether each observation passed.

Do not mark physical-device QA complete from emulator/CI results. Keep visual geometry approval and rule-profile acceptance as separate gates.
