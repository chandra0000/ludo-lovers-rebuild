# Match screen implementation ledger (2026-11-12)

**Scope:** PR #22, `feat/match-command-session-boundary`. This ledger is the required baseline before any further match-screen change. **Do not regenerate, recrop, or replace user-approved assets without explicit approval.**

## Already implemented — do not redo

| ID | Existing implementation | Evidence | Preservation rule |
| --- | --- | --- | --- |
| MS-01 | Approved full board `assets/images/board/ludo_board_glass.webp` | `pubspec.yaml`; `approved_board_flame_view.dart` | Preserve original bytes and board geometry |
| MS-02 | Cropped board `assets/images/board/extracted/board_exact.webp` | Repository asset; `match_board_artwork.dart` | Verify actual crop before changing it |
| MS-03 | Four cropped avatars | `assets/images/board/extracted/avatar_{aldo,you,bob,emma}.webp`; `match_profiles_layer.dart` | Do not replace with placeholders |
| MS-04 | Animated interactive dice | `luxury_dice.dart`, `match_dice_layer.dart`, `dice_control_dock.dart` | Preserve animation and tap behavior |
| MS-05 | Animated glassy pawns and collision stacking | `glassy_pawn.dart`, `pawn_animator.dart`, `pawn_layout_solver.dart`, `match_screen.dart` | Preserve movement and board anchors |
| MS-06 | Flutter responsive viewport and rendering capture | `match_board_viewport.dart`, `match_screen_capture_test.dart` | Keep 576x1024 logical canvas |
| MS-07 | Flame board renderer (existing alternative) | `approved_board_flame_view.dart` | Do not silently switch renderers |
| MS-08 | Board, dice, pawn, session and screenshot tests | `apps/mobile/test/` | Keep tests and add actual pixel-level visual assertion |
| MS-09 | Authoritative session/command boundary | `match_session.dart`, `match_controller.dart` | Never move game rules into widgets |

## Verified current wiring

- `MatchScreen` currently renders `MatchBoardArtwork` as the bottom layer; **it does not instantiate `ApprovedBoardFlameView`**.
- `MatchBoardArtwork` draws `board_exact.webp` in a positioned rectangle computed from reference dimensions 864x1536.
- `BoardGeometry` uses coordinates measured from the **810x1440 full source artwork**; this is a potential coordinate/crop-space mismatch requiring screenshot validation, **not a proven root cause**.
- The user-supplied device screenshot has floating pawns and no visible board. Asset presence and successful decoding alone do not prove a visible, aligned board.
- Existing `match_screen_capture_test.dart` saves PNG output, but does not compare it to an approved golden reference. A green pipeline is not visual approval.
- `approved_board_asset_integrity_test.dart` checks pixel visibility of the standalone asset, not the complete composed match screen.

## Prioritized investigation and performance improvements

| Priority | Issue | Required evidence before changing behavior | Acceptance criterion |
| --- | --- | --- | --- |
| P0 | Missing board in installed app | Inspect exact committed `board_exact.webp` alpha/color, compare full source and crop, inspect screenshot artifact from current CI and on-device build | Board visible in final composed 393x873 screenshot and physical Android build |
| P0 | Cropped artwork and dynamic pawns may use different coordinate spaces | Overlay measured board anchors, yard sockets and 52 track cells on current render | Pawns align with approved yard sockets and track cells |
| P1 | UI drift (avatars, header, chat, dice, turn indicator) | Compare screenshot against approved Library reference and existing cropped assets | Pixel-level or tolerance-based visual golden approval |
| P1 | Rendering performance | Profile Flutter frame times and raster cache on target 6.1–6.9-inch Android devices; inspect rebuild counts | No avoidable whole-screen rebuilds during dice/pawn animations; no dropped frames in representative test |
| P2 | Repeated player lookups and cluster recomputation on animation frames | Measure rebuild counts before optimization | Improve only measured hotspots; keep behavior unchanged |
| P2 | Render-mode consistency | Determine whether Flutter artwork or Flame view is canonical; benchmark both | One explicit, tested renderer; no hidden fallback or duplicate artwork |

## Change protocol — mandatory for each subsequent implementation

1. Record issue ID, baseline commit, screenshot or profiler evidence, and proposed minimal change.
2. Preserve approved assets and domain rules; never re-create existing cropped assets or animation components.
3. Add or update a targeted test (including composed screenshot pixels for visual fixes).
4. Make one scoped commit and record its SHA, affected files, test results and visual evidence.
5. Check GitHub Actions **verify and Android APK** jobs; do not call the change complete until both pass and the visual acceptance is confirmed.
6. Append an entry under **Implementation history** below.

## Implementation history

- **LEDGER-001 (2026-11-12):** Audited latest PR #22 source tree, extracted assets, renderer selection, dice/pawn implementations, and regression-test inventory. Documentation-only baseline; no game logic, approved artwork or runtime rendering changed. Previous pipeline #990 failed on analyzer trailing-comma lints; corrected in commit `98c4cb9`. CI #992 was in progress when reviewed.

- **MS-10 (2026-11-12, commit `ed006e8`):** Strengthened `apps/mobile/test/match_screen_capture_test.dart` to inspect the composed 393x873 screenshot and reject a missing/dark board or absent colored cells. Existing board crop, dice/pawn animation and domain rules unchanged. CI and device visual verification pending; this is detection, not a verified visual fix.

- **PERF-001 (2026-11-12, commit `ed50905`):** In `match_screen.dart`, index `LudoPlayer` instances by `PlayerColor` once per animated frame and pass the resolved player to each pawn widget, eliminating repeated `firstWhere` searches for each pawn. No approved asset, route geometry, game rule or dice behavior changed. Baseline CI #996 passed (before this commit); new commit CI and frame-time measurement pending. Do not claim FPS gains until profiled.
