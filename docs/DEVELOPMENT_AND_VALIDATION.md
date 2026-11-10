# Development and validation workflow

This project uses fast continuous checks for everyday work and a separate Android integration checkpoint for substantial changes. The goal is to shorten feedback time without weakening gameplay or release confidence.

## 1. Every commit and pull request: fast CI

The `Flutter foundation checks` workflow runs automatically for pushes to `main` and feature branches, and for pull requests targeting `main`.

It checks:

- Formatting of Dart files changed by the current commit or pull request. Existing formatting debt in untouched files does not block unrelated work.
- Flutter static analysis with fatal infos.
- Unit and widget tests, including game rules, geometry, onboarding, navigation, dice and pawn interactions.
- The canonical board and screenshot diagnostics when the tests produce them.
- Android profile and split release APK builds.

The routine workflow deliberately does not boot an Android emulator. Emulator startup and integration are too slow and unreliable to repeat for every small UI or documentation change.

## 2. Major changes: Android integration checkpoint

Run the separate `Android integration (checkpoint)` workflow when a change affects any of the following:

- Game engine rules, turn sequencing, captures, safe cells, winning or AI decision flow.
- Board artwork, board geometry, pawn coordinates, hit testing or stacked-pawn selection.
- Dice and pawn animation/input coordination.
- Navigation, onboarding, match lifecycle or repeated match entry/exit.
- Android platform configuration, plugins, permissions, audio or haptics.
- A dependency or architectural change that crosses multiple app layers.

To run it:

1. Open GitHub Actions in `chandra0000/ludo-lovers-rebuild`.
2. Select `Android integration (checkpoint)`.
3. Choose **Run workflow** on the branch containing the major change.

For pull requests, adding the `run-android-integration` label also starts the checkpoint.

The checkpoint uses an Android emulator and is intentionally separate from routine CI. A successful emulator test is evidence of integration behaviour, not proof of physical-device haptics, speaker output, thermal behaviour or GPU performance.

## 3. Before a release: full acceptance

Before treating a build as release-ready:

- Confirm routine CI and the Android integration checkpoint are green on the exact release commit.
- Install the profile APK on a physical Android phone.
- Verify board/pawn alignment against the canonical 810×1440 artwork.
- Exercise dice rolling, pawn release, normal movement, captures, extra turns, safe cells, shared-pawn selection, win flow, restart and repeated navigation.
- Check TalkBack/semantics, touch targets, haptics and sound.
- Profile UI/raster frame times and memory during repeated movement and match entry/exit.
- Record the device model, Android version, test duration and observed results.

Do not mark physical-device checks complete from emulator or widget-test results alone. Keep `BoardGeometry.visualApprovalPending` true until the owner has visually approved the board on a physical device.

## 4. Diagnostic screenshot artifacts

The current board-preview and match-canvas screenshot tests are diagnostic captures, not approved visual-regression baselines. No checked-in golden baseline is currently maintained for these two captures.

Routine CI runs `flutter test --update-goldens` so those tests can generate fresh PNG captures, then uploads them as artifacts for human inspection. This does not prove that the current board artwork or pawn anchors are visually correct; it only records the rendered output.

Do not describe these captures as automated visual approval. If stable visual-regression baselines are introduced later, check them in separately and run those comparison tests without `--update-goldens`. Update a baseline only after reviewing and approving the visual change.

## 5. Engineering guardrails

- Keep one authoritative domain engine for rules and state transitions.
- Keep rendering coordinates centralized in `BoardGeometry`; do not introduce a second widget-level coordinate map or a uniform-grid shortcut for the canonical artwork.
- Keep animations presentation-only; the engine remains authoritative for dice results and legal moves.
- Add a focused regression test for each fixed defect.
- Prefer seeded, bounded simulations over nondeterministic or unbounded AI tests.
- Measure before optimizing. Avoid adding dependencies or speculative caching/clustering for a 16-pawn board without evidence.
- Do not claim device performance, haptics, audio, visual approval or release readiness until the corresponding check has actually been performed.
