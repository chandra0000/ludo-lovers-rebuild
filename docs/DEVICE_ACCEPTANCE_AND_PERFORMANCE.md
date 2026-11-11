# Physical Android acceptance and performance protocol

Status: **Pending physical-device execution and owner sign-off**

This protocol turns the P0 board/gameplay and P1 performance requirements into repeatable evidence. Emulator and widget-test results are supporting checks only; they do not satisfy physical-device gates.

## 1. Required device record

For every run, record:

- Device manufacturer/model and chipset.
- Android version/build and display refresh rate.
- Available RAM and free storage before the run.
- App commit SHA, APK variant, APK SHA-256 and install date.
- Display resolution, display scaling/font scaling and battery level.
- Test duration, tester and date.
- Whether the device was cool/idle before cold-start measurements.

Use at least one representative mid-range Android phone. Add a lower-memory device before public release if available.

## 2. P0 gameplay acceptance

Use a deterministic test setup or debug fixture so the same positions can be repeated. Verify both the engine result and what the player sees:

- Safe squares: all four coloured starts and four gold stars match the canonical artwork; an opponent cannot capture a pawn on any of them.
- Three sixes: first and second six retain the turn; the third six forfeits that roll without moving a pawn and hands off the turn.
- Blockade: a same-colour pair blocks an opponent from passing or landing; the UI offers only legal alternatives; if every pawn is blocked, the turn is passed; removing one pawn opens the route.
- Bonus turns: six, capture and home completion each award the defined bonus; simultaneous bonus conditions award only one bonus roll.
- Finish/win: exact finish is required, overshoot is rejected, all four pawns must finish, and no further roll/move is accepted after a winner is declared.
- Human/AI parity: replay the same positions with a human and AI seat and verify both transitions are accepted/rejected by the same engine profile.

Capture a screen recording for each rule scenario and note the starting fixture, dice value, expected result and observed result.

## 3. P0 board visual acceptance

Keep the canonical 810×1440 artwork unchanged. At normal display scaling:

1. Capture the empty board and all 16 yard pawns.
2. Capture a pawn on each of the four coloured start cells and four gold stars.
3. Capture a single pawn on representative shared-track cells, all four home lanes and the finish area.
4. Capture two same-colour pawns stacked on a shared cell, including one case with an overlapping opponent pawn nearby.
5. Tap each pawn footprint and verify the intended pawn is selected. For stacks, verify the chooser is reachable and each option can be selected.
6. Repeat on portrait 360×800, 393×873 and 412×915 logical-pixel layouts where supported; do not crop or stretch the source artwork.
7. Inspect the screenshot at native resolution, not only a scaled chat preview.

Record centre offset in physical pixels for every sampled pawn. Target <=2 physical pixels from the intended artwork centre, with no clipping or unintended overlap. Verify the effective hit target is at least 44×44 logical pixels and that adjacent pawns remain independently selectable.

**Pass condition:** product owner approves the captures from the actual phone and the recorded touch tests pass. Until then keep `BoardGeometry.visualApprovalPending = true`.

## 4. P1 performance profiling

Use a profile build installed directly on the phone. Do not use debug-build timings as release performance evidence.

### Startup

- Perform five cold launches after force-stop; record time from tapping the app icon to the first interactive home screen.
- Perform five warm launches; record the same interval.
- Report median and slowest result, not only the best run.

Initial target: cold-start median <=3.0 s and warm-start median <=1.5 s on the selected mid-range device. If the target is missed, profile before changing assets or adding caches.

### Frame pacing

Record a 3-minute profile session containing dice rolls, pawn release, a 6-step move, capture, bonus roll, stack selection and repeated turn changes.

- Inspect Flutter UI and raster frame timings in DevTools.
- For a 60 Hz display, target p95 frame duration <=16.7 ms.
- Record frames >16.7 ms and >33.3 ms, longest frame, and whether any visible hitch occurs during pawn/dice animation.
- Repeat at the device's default refresh rate and note that rate in the report.

### Memory and lifecycle

- Record process memory after launch, after five minutes of play, after 20 minutes of play, and after ten match entry/exit cycles.
- Record peak memory and whether memory returns near baseline after leaving a match.
- Background and resume the app during dice animation and during pawn movement; verify no duplicated move, stuck AI turn or lost accepted state.
- Record crashes, ANRs, dropped frames and any progressive memory increase.

### Battery

- Start from a known battery percentage with screen brightness and refresh rate fixed.
- Run a 20-minute representative match and a separate 20-minute idle-home baseline under the same conditions.
- Record percentage-point drain for both; report the difference as an observation, not a universal battery guarantee.
- Record device temperature if available. Stop if the device becomes uncomfortably hot.

## 5. Results template

| Metric | Result | Target / interpretation |
|---|---|---|
| Cold start median / max | Pending | <=3.0 s median |
| Warm start median / max | Pending | <=1.5 s median |
| p95 frame duration | Pending | <=16.7 ms at 60 Hz |
| Frames >33.3 ms | Pending | Investigate visible hitches |
| Peak process memory | Pending | Record; compare across runs |
| Memory after 20 min | Pending | No unexplained upward trend |
| Battery: match / idle | Pending | Record both and delta |
| Board centre offsets | Pending | <=2 physical px sampled |
| Hit targets | Pending | >=44×44 logical px |
| Rule scenario recordings | Pending | All required scenarios captured |
| Owner visual approval | Pending | Explicit approval required |

## 6. Release gate

Do not mark P0 visual acceptance or P1 performance complete from GitHub Actions, screenshots rendered only in CI, or Android emulator tests. Attach the device record, screen recordings, screenshots and profiling exports to the release PR. Keep the compatibility profile as default and Classic opt-in until gameplay tests, safe-cell artwork review and owner acceptance are complete.
