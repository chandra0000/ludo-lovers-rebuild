# Ludo Lovers — Commercial-quality engineering and visual roadmap

> Reviewed 2026-11-13. **This is an execution contract, not a claim of release readiness.**
> Canonical project plan: [Notion Commercial Readiness Plan](https://app.notion.com/p/417d7b2be1cc81f08f6afbd850391a3a).
> The source of truth for implementation progress is GitHub code, CI results and physical-device acceptance records.

## Product target and trade-off

Deliver an Android-first **polished offline Ludo game** with deterministic gameplay, a faithful user-approved glass board, accessible controls, strong performance and a reliable signed Play distribution. Competitive online matchmaking, social and tournaments follow the stable offline release. Compete on game quality and distinct branding, not by copying Ludo King assets or UI.

The official logo and the four approved player colors are locked: Orange `#FF8928`, Green `#33FF28`, Magenta `#F428FF`, Blue `#289EFF`. Never replace or modify approved artwork without owner review.

## Evidence and current status

| Area | Code/evidence | Status |
|---|---|---|
| Core gameplay | `lib/src/game/domain/ludo_game.dart`, immutable `MatchSession` commands | Present; rule variants and device acceptance are not complete |
| UI orchestration | `lib/src/features/match/match_screen.dart` (~985 lines at PR #26) | Needs further decomposition |
| Existing CI | [PR #24](https://github.com/chandra0000/ludo-lovers-rebuild/pull/24), [PR #26](https://github.com/chandra0000/ludo-lovers-rebuild/pull/26) | Both draft, green on their heads, not merged |
| Approved composition | `assets/images/board/ludo_board_glass.webp`, 810x1440 | Approved immutable reference; still contains baked UI |
| Default board renderer | `match_board_artwork.dart` uses `extracted/board_exact.webp` | Derived crop; must verify against original |
| Full-art preview | `approved_reference_plate.dart` controlled by `LUDO_APPROVED_ART` | Preview-only, disabled by default |
| Device quality | `docs/DEVICE_ACCEPTANCE_AND_PERFORMANCE.md` | Physical-device verification and owner approval outstanding |
| Release packaging | `.github/workflows/flutter.yml` builds split APKs after generated Android project | Signed release AAB and Play submission not verified |

## Root cause: static screenshot is not an interactive game screen

The **full** `ludo_board_glass.webp` already contains player portraits, names, status information, decorative die and controls. Placing mutable Flutter/Flame UI over those baked elements produces double dice, fixed identities, opaque text patches and non-resizable hit regions. Cropping just the central board avoids baked UI but can remove the approved glass frame and loses a trustworthy transform if the crop came from another source size.

**Decision (proposed for owner approval): use a layered production scene.**

1. **Immutable reference**: preserve the original file and compute SHA-256.
2. **Approved clean derivative**: retain fixed board, frames and background, but remove mutable UI pixels (die, names, portraits, turn label). Do not edit the original. Derivative is a separate reviewed asset with a recorded hash and diff.
3. **Calibrated board layer**: one authoritative presentation transform from source pixels to the 576x1024 stage, with normalized yard/track/home/finish anchors. The *gameplay* board topology is not regenerated from artwork coordinates.
4. **Animated game layer**: move pawn and capture effects using **accepted engine events**. Maintain origin/destination and walk steps in presentation state only.
5. **Independent Flutter controls**: avatars, labels, connection state, animated die, turn timer, menu, chat and rematch are live widgets. Respect semantics, device-safe insets and logical-pixel input targets.
6. **Viewport**: maintain uniform board aspect ratio, add non-interactive dark/gold ambient background to remaining safe-area bands instead of stretching or cropping the 9:16 board.

### Geometry contract and anti-drift checks

- Original image: 810x1440. Design stage: 576x1024. Preserve single uniform scale, source-to-stage (x' = x(576/810)), (y' = y(1024/1440)).
- Nominal board bounding square: stage `Rect.fromLTWH(17,205,542,542)` is a *design reference*. The actual track and yard wells have hand-calibrated nonuniform centres in `BoardGeometry`, which remain authoritative for pawn presentation until image-alignment review.
- 52 shared route cells, entries `0/13/26/39`, 4 diagonal artwork connectors `4/17/30/43`, four five-cell lanes, sixteen yard centres, exact finish are immutable gameplay/geometric contracts.
- Existing extracted board renderer uses a separate 864x1536 reference coordinate system. Before promoting the extracted crop, **measure its pixel bounds against the 810x1440 approved asset**. Do not assume a similar aspect ratio means equivalent tile anchors.
- For a 576-unit stage on a 360 logical-pixel-wide display, stage scaling is 0.625. A 44-unit game control shrinks to 27.5dp. The effective accessible touch target **must be verified after transform**; do not confuse art-pixel size with logical screen size.
- Sample yard, start, safe star, diagonal connector, home and finish pawn centres against the rendered image at 360x800, 393x873 and 412x915; require <=2 physical-pixel offset on representative physical devices before sign-off.

### Rendering technology decision

- **Keep Flutter** for scalable platform controls, overlays, text, navigation, accessibility and input.
- Use the current painter / Flutter pawn renderer unless **profile-build measurements** show a rendering limit; alternatively transition only the board/pawn scene to Flame `World` with a `CameraComponent.withFixedResolution` viewport. Do not migrate `MatchSession` into Flame.
- Repaint static assets separately from moving pawns; avoid rebuilding the entire `MatchScreen` subtree every pawn animation tick.
- Cache decoded image at an appropriate physical width and precache where it prevents blank screen transitions. Validate memory in repeated enter/exit sessions. Do not repeatedly decode full-size portrait images on hot paths.
- The dice **visual** reads the accepted roll; it does not determine randomness, legality or turn order. Disable or reduce movement and dice animation when `MediaQuery.disableAnimations` is set.

## Game-engine and code-quality gates

- Every input is a `MatchSession` command carrying `matchId`, `actorId`, `expectedStateVersion` and idempotent `commandId`. Reject stale, duplicate and wrong-actor commands without mutation.
- Use versioned rule profiles. Keep `LudoRuleProfile.currentV1` compatible; `classicV1` remains opt-in until owner approval. Do not infer new 2/3/6-seat or team rules from 4-seat geometry.
- Match results and UI feedback are **event-derived**: `PawnMoved` supplies actual animated progress; `PawnCaptured`, `PawnFinished`, `ExtraTurnGranted`, `GameCompleted` supply result text. Never infer a bonus roll from a capture without the matching engine event.
- Tests: 6-to-enter, no legal move and pass, three consecutive sixes, blockade, multi-capture, safe squares, 52-cell wrap, exact finish, winner, rematch, deterministic replay and persist/restore. Include negative commands and every seat orientation. Add property/invariant tests before extensive profile additions.
- Refactor `MatchScreen` progressively into separate rendering, input, HUD, persistence and command scheduling modules. Use tests first; preserve public widget keys and user touch behavior while extracting.
- Architectural rule: domain cannot import Flutter/Flame, image assets, UI widgets or network transports. Distinguish logical board topology from pixel-space calibration in future extraction.

## Performance acceptance matrix (proposed engineering targets)

| Measure | How to collect | Gate |
|---|---|---|
| Cold start / time-to-interactive | profile APK on physical midrange and low-memory devices; repeated cold starts | establish measured baseline and reject regressions |
| Frame time / motion | Flutter DevTools Performance View, profile mode, gameplay dice + pawn move scenarios | target 60 fps on capable devices and p95 frame time <=16.7ms; verify instead of assuming |
| Bitmap and process RAM | DevTools Memory/Android profiler, idle + repeated match navigation | no steadily growing retained scene/images; record maximum per device |
| Stability | native Android crash/ANR traces, restore/restart tests, Android vitals after launch | no known P0 black screen/freeze; meet or beat Play bad-behavior thresholds |
| User interaction | manual tapping on 6.1–6.9-inch devices and Android accessibility services | effective >=44x44dp hit targets; independent pawn selection; clear active turn |
| Portrait art | approved reference vs screenshots, sampled pawn anchors | full art not distorted/cropped; <=2 physical-pixel centre error on selected cells |

Do not make claims about frame rate, time-to-first-frame or memory stability from `flutter test` or from a green APK build alone.

## Release sequencing

1. **Freeze stable baseline:** [PR #24](https://github.com/chandra0000/ludo-lovers-rebuild/pull/24) architecture and [PR #26](https://github.com/chandra0000/ludo-lovers-rebuild/pull/26) visual preview remain draft until reviewed and accepted.
2. **Engine/presentation quality:** typed event projection, rule matrix and replay invariants; then smaller widget/interaction coordinators.
3. **Art production:** designer/owner-approved clean derivative of locked full reference, masks/frames if needed, provenance manifest and visual-golden review; no copied competitor assets.
4. **Offline complete:** local match modes, bots, accurate animations, capture/finalization, restart/resume, accessibility and battery/memory stability on physical devices.
5. **Android commercial release:** pinned reproducible Android project, target API >=36 for new/updated phone apps as of Nov 2026, signed release App Bundle (AAB), Play App Signing, package identity, adaptive icon, versioning, privacy/Data Safety, content rating and screenshots.
6. **Testing and gradual rollout:** Play internal/closed testing, prelaunch report, owner acceptance, staged release, Android vitals monitoring. New qualifying personal Play developer accounts require 12 opted-in closed testers continuously for 14 days before requesting production access.
7. **After stable offline release:** online authoritative match server, matchmaking by skill/region/latency/party size, reconnect, protected virtual-coin ledger and tournaments, as separate releases.

### Stop-ship checks

- [ ] No P0 defects, black screens or freezing on target physical Android devices.
- [ ] User-approved visual match screen, dynamic avatars/die/HUD, and measured pawn alignment/touch targets.
- [ ] Format, strict analyze, deterministic tests, screenshot goldens, device integration suite and Android release pipeline green.
- [ ] Signed AAB, package name/version/target SDK, legal/privacy requirements, Play Console testing and store approval verified.
- [ ] Explicit owner sign-off, exact build hash recorded and rollback procedure documented.

## Official references

- [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter rendering performance](https://docs.flutter.dev/perf/rendering-performance)
- [Flutter SafeArea and MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery)
- [Flame camera, world and fixed-resolution viewports](https://docs.flame-engine.org/latest/flame/camera.html)
- [Flame GameWidget and overlays](https://docs.flame-engine.org/latest/flame/game_widget.html)
- [Google Play target API levels](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Android vitals](https://developer.android.com/games/optimize/vitals)

This plan intentionally preserves the user-approved art and business direction while distinguishing **verified**, **implemented**, **proposed** and **not yet validated** work.
