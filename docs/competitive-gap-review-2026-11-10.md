# Ludo Lovers — competitive and repository review

**Review date:** 2026-11-10  
**Repositories compared:** `chandra0000/ludo-lovers-rebuild` (active implementation) and `chandra0000/ludo-lovers` (legacy reference only).  
**Competitor reference:** Ludo King by Gametion.

## Executive assessment

The rebuild is the better engineering foundation, but it is not yet a Ludo King competitor as a released product. It has a more disciplined single-engine / single-geometry architecture and a deliberately measured artwork coordinate map. The legacy repository contains substantially more feature breadth and automated tests, so useful gameplay and UX behaviour must continue to be selectively recovered without copying its duplicate architecture.

- **Rebuild engineering quality:** 8.0/10
- **Legacy repository engineering quality:** 7.6/10
- **Rebuild product/competitive readiness against Ludo King:** 3.0/10

These are engineering-review judgements, not store ratings, benchmark results, or claims of market readiness.

## Glass-cone pawn and board alignment audit

### Pawn design: implemented in code

The rebuild contains `apps/mobile/lib/src/game/presentation/glassy_pawn.dart`. It paints a tapered cone body, broad elliptical foot, multi-stop colour gradient, translucent/specular streak, rim, ground shadow, and active/legal-move halo. It is not the old circular token treatment.

The widget is integrated into `MatchScreen`. The current implementation supports a 30 px standard visual size and a 16 px compact stacked size.

### What has actually been validated

- Widget smoke tests verify that the custom-painted pawn renders without exceptions and has the expected standard/compact dimensions.
- Live match-widget placement tests verify rendered pawn centres against the centralized anchor contract for representative shared-track, home-lane, and finish positions at a 393×873 logical viewport.
- Numeric geometry tests pin all 52 shared-track centres, all 20 home-lane centres, all 16 yard socket centres, and the finish anchor to source-artwork pixels.
- The source artwork and diagnostic calibration overlay are available as CI artifacts. Latest routine CI run #453 completed successfully and uploaded the match-canvas and board-calibration artifacts.

### What has NOT been validated

- No physical Android device visual sign-off has been recorded.
- There is no committed golden-image comparison proving the pawn's rendered silhouette, reflections, colour fidelity, and anti-aliasing at device scale.
- The live widget placement test does not yet render/assert every one of the 16 yard pawns, every stack arrangement, or every compact viewport.
- A centre-coordinate assertion does not prove that the pawn footprint fits inside each artwork socket without touching borders or neighbouring pieces.

**Conclusion:** the glassy cone pawn exists and is wired into gameplay. Its coordinate foundation is well covered, but full visual alignment and device acceptance are still open. Do not describe pawn alignment as fully approved yet.

## Repository comparison

GitHub's current `main` trees were compared on 2026-11-10. Counts below are tracked source-tree files matching the stated extensions/patterns; they are not a measure of code quality by themselves.

| Measure | Rebuild | Legacy reference |
|---|---:|---:|
| Tracked files | 59 | 134 |
| Dart files | 33 | 80 |
| Dart test files | 16 | 50 |
| Markdown documents | 18 | 35 |
| Image assets (PNG/WebP/JPG/SVG) | 3 | 13 |

### Engineering scorecard

| Dimension | Rebuild | Legacy | Assessment |
|---|---:|---:|---|
| Architecture and source-of-truth discipline | 8.7 | 7.7 | Rebuild has one domain engine and one centralized geometry contract |
| Core engine foundation | 8.3 | 8.5 | Legacy has more edge-case and mode coverage; rebuild has cleaner state/command boundaries |
| Board geometry foundation | 8.8 | 7.8 | Rebuild uses measured full-artwork anchors; visual/device approval remains open in both |
| Pawn visual implementation | 8.4 | 7.2 | Rebuild paints a true glass-finish cone; legacy pawn is a glossy circular token |
| Gameplay and mode breadth | 6.8 | 8.2 | Legacy includes more recovered modes and acceptance scenarios |
| Automated test breadth | 7.6 | 8.8 | Legacy has 50 Dart test files versus 16 in rebuild; selectively port missing edge cases |
| CI and delivery discipline | 8.5 | 8.0 | Rebuild has strict format/analyse/test and profile/release APK workflow |
| Documentation and decision traceability | 8.5 | 8.7 | Both have substantial docs; rebuild needs to keep the migration and status docs current |
| Release readiness | 6.5 | 6.5 | Both still have outstanding physical-device and product acceptance gates |

The overall scores are weighted engineering judgements. The rebuild wins on maintainability and geometry; the legacy repository wins on breadth. Keep the rebuild as the only active source of truth and mine the legacy repository for missing tests/features rather than merging the repositories.

## Ludo King competitive baseline

The current Google Play listing reports **1B+ downloads**, a **4.1-star** rating and **10.3M reviews**. Its feature listing includes online play for 2–6 players, offline computer/local play, 8-player tournaments, monthly seasons, daily goals, and the Adda social club. Ludo King's official features page also lists voice chat, 2-vs-2 Team Up, Quick Mode, six-player online multiplayer, themed inventory and tournament mode.

Sources checked 2026-11-10:
- [Ludo King on Google Play](https://play.google.com/store/apps/details?id=com.ludo.king)
- [Ludo King official features](https://ludoking.com/features)
- [Ludo King official FAQ](https://ludoking.com/faq)
- [Gametion's Ludo King overview](https://gametionglobal.com/ludoking.html)

Ludo King is a mature live product with a large player network and ongoing operations. Comparing only board visuals or local AI would understate the competitive gap.

## Prioritized gaps for Ludo Lovers

### P0 — finish a trustworthy Classic match

1. Complete the Classic rules acceptance matrix: entry/exit rolls, three consecutive sixes, safe cells, captures, own-colour stacks, opponent blockades, bonus turns, exact finish/overshoot, and win conditions.
2. Obtain owner visual sign-off on the complete board route, all yard sockets, pawn footprints, stacks, and home lanes using the canonical full-resolution artwork.
3. Run the Android integration checkpoint and physical-device QA at the target phone size; capture and review real-device screenshots.
4. Add rendered pawn visual goldens and a full 16-yard live-placement test, including stack overlap and legal hit-target behaviour.

### P1 — recover differentiating local play

1. Port missing engine edge-case tests from the legacy repository selectively.
2. Restore and acceptance-test Team Up (2-vs-2), local pass-and-play, and robust AI difficulty levels.
3. Add match pause/resume, lifecycle recovery, rematch, match history and accessibility/reduced-motion support.
4. Profile frame pacing, memory, startup and battery on a physical low-end Android device.

### P2 — become a social multiplayer product

1. Add account identity, friend graph, invites/private rooms and presence.
2. Build an authoritative online game service: server-validated legal moves, fair dice/RNG auditability, reconnect/resume, anti-cheat and idempotent commands.
3. Add moderation: mute, block, report, chat safety and privacy controls.
4. Add progression, cosmetics, seasons/events, tournaments, leaderboards and sustainable monetization only after fair-play foundations.

Do not begin with cosmetic monetization or a tournament UI before the core match is visually accepted and the authoritative multiplayer model is designed.

## Latest validation evidence

Routine GitHub Actions run [#453](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/42822538282) completed successfully for commit `4917c649399fef5f0ca88bf42bbf650feff758e5`. It uploaded split profile/release APKs, canonical board artwork, board-calibration preview and 393×873 match-canvas screenshot artifacts.

This CI result is not a physical-device test and does not close the visual-approval gate.
