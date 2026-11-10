# Legacy feature recovery plan

Last reviewed: 2026-11-10
Active implementation repository: `chandra0000/ludo-lovers-rebuild`
Reference repository: `chandra0000/ludo-lovers`

## Goal

Recover the useful, verified product behaviour from the legacy repository without restoring its overlapping engines, duplicated coordinate sources, obsolete UI, or unverified assumptions. The rebuild remains the only runtime source of truth and all routine implementation is committed directly to `main`.

This is an implementation backlog and acceptance contract, not a claim that the listed features are already complete.

## Non-negotiable product constraints

- Preserve the approved black-and-gold premium glassmorphism identity and palette: Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`.
- Preserve the canonical full-screen 9:16 board artwork unchanged at `apps/mobile/assets/images/board/ludo_board_glass.webp`; do not crop, stretch, recolor, rename, or substitute it. The requested `ludo_board_glassy.webp` naming must not cause a silent asset swap.
- Preserve the glass-cone pawn silhouette, translucent highlights/reflections, circular base, colour identity, stack sizing and active/legal-move highlights.
- Keep exactly one authoritative game engine, one board-coordinate map, and one rule implementation. No legacy runtime imports or parallel engines.
- Rules remain in the domain layer. UI and animation display accepted state; they do not decide legality.
- Preserve 52 physical shared-track cells, seat entry indexes Orange 0 / Green 13 / Magenta 26 / Blue 39, five private lane cells, and a separate centre finish. Route/safe-cell visual approval remains gated by measurement.
- Do not silently promote provisional Classic rules or Team Up semantics to defaults.
- A green CI run is not proof of visual calibration or physical-device acceptance.

## Legacy-to-rebuild feature inventory

| Legacy capability / durable behaviour | Rebuild status | Target module | Acceptance evidence |
|---|---|---|---|
| Four-player local match, four pawns each, Orange → Green → Magenta → Blue | Implemented foundation | `game/domain/ludo_game.dart`, `features/match/` | Full-match deterministic engine tests; turn order and all pawn states verified |
| Six to leave yard, exact finish, basic unsafe-cell capture, bonus on six/capture | Implemented in current profile | `game/domain/ludo_game.dart` | Boundary, capture, no-legal-move and bonus-turn tests |
| 52-cell physical route and five-cell private lane + centre finish | Present but provisional | `game/domain/board_geometry.dart` | Route uniqueness, adjacency/connector contract, lane and finish mapping; screenshot calibration |
| Four yard zones and 16 pawn sockets | Present but provisional | `game/domain/board_geometry.dart` | Each socket independently measured against source art and rendered screenshot; <=2 logical-canvas px anchor error |
| Safe/star cells and diagonal connector candidates | Provisional only | `game/domain/board_geometry.dart` | Pixel evidence and owner approval; tests assert exact approved identities |
| Board preview / geometry audit tooling | Implemented diagnostic overlay; still provisional | `features/board_preview/` | Preview overlays all 16 yards, 52 route cells, candidate connectors, safe cells, five-cell lanes and centre finish from the one BoardGeometry map; visual calibration remains open |
| Splash and onboarding | First-launch onboarding implemented; CI acceptance pending | `features/splash/`, `features/onboarding/` | Splash routes first launches to three-page onboarding; skip/get-started persists completion locally; returning launches go to home |
| Player/mode setup | Four-player pass-and-play plus 1–4 human seats with remaining AI seats implemented; validation pending | `features/setup/`, `features/match/` | Human count selection assigns the remaining colours to AI; Team Up remains disabled |
| Local human-vs-AI opponents | Seeded legal-action strategy and match orchestration implemented; full-match acceptance pending | `game/domain/ai/seeded_ludo_ai.dart`, `features/match/` | AI evaluates only engine legal pawn actions; seeded dice and tie-breaking; AI turns are coordinated after human/AI moves |
| Team Up 2-vs-2 | Intentionally deferred from first milestone | Separate rules profile/mode after Classic acceptance | Team mapping Orange+Magenta vs Green+Blue; bonus-roll recipient, finished-player skip, team victory, safe cells, friendly/opposing stacks tested |
| Animated dice and glass-cone pawns | Implemented foundation | `game/presentation/` | Widget tests for animation states, reduced-motion handling, hit targets and visual consistency |
| Pawn step animation, capture/finish feedback, stack selection | Partially implemented | `features/match/` | Movement follows engine-resolved intermediate positions; no input during transition; correct shared-cell pawn selection |
| Sound and haptics | Not yet recovered / verify exact legacy behaviour before port | `game/presentation/feedback/` | User preference toggle, lifecycle-safe playback, no sound in widget tests by default |
| Accessibility and responsive layout | Partial / not fully accepted | App presentation layer | Semantics labels, minimum touch targets, text scaling, portrait/landscape viewport tests |
| Pause/resume and app lifecycle resilience | Local snapshot recovery implemented; physical lifecycle acceptance pending | `features/match/`, `game/domain/persistence/saved_match_store.dart` | Accepted state saved after transitions and on app background; home offers resume/discard; verify process recreation and foreground AI/animation behaviour on Android |
| Save/resume, snapshot schema and durable idempotency | Snapshot codec and local persistence implemented; event replay missing | `game/domain/ludo_game.dart`, `game/domain/persistence/saved_match_store.dart` | Versioned schema, corrupt snapshot rejection, AI configuration restored, duplicate command rejection after reload; event replay remains future work |
| Launcher icon / release branding | Partial | Android app config + canonical branding asset | Generated launcher icon inspected on Android launcher; no duplicated brand artwork |
| Online multiplayer/backend | Not in current recovery scope | Future architecture only | Separate security, authority, reconnect, anti-cheat and integration plan; do not block local milestone |

## Priority and implementation sequence

### P0 — correctness and artwork readiness (do first)

1. **Finish board geometry calibration.** Measure the exact board-grid bounds and all 16 yard socket centres from the canonical source image. Generate diagnostic placements for all route anchors, connectors, safe cells, lanes, finish and stacks. Update only `BoardGeometry`. Keep visual approval false until a rendered screenshot is compared at 360×800, 393×873, 412×915 and 800×360.
2. **Resolve route topology explicitly.** Preserve the legacy warning that the 52-cell loop contains intentional diagonal/connector transitions; do not falsely require every edge to be orthogonal. Verify each connector and player-relative route mapping with tests and pixel evidence.
3. **Complete Classic rules parity as opt-in.** Test third consecutive six consumes the roll and passes without moving; finish bonus; bonuses do not stack into multiple immediate rolls; exact finish; capture and safe-cell semantics. Keep the compatibility profile as default until product approval.
4. **Close rule ambiguity.** Specify own-pawn stacking, opponent stacks/blockades, multiple pawns captured on a landing, player skip after all pawns finish, and match completion policy. No guessed rules.

P0 acceptance: all domain tests pass; one authoritative geometry map; screenshot anchors within <=2 logical-canvas pixels; no rule profile silently changed; CI green.

### P1 — recover the local product experience

5. Restore first-launch splash/onboarding and returning-user navigation.
6. Restore a player/setup flow for supported local player counts. Do not expose modes until implemented and tested.
7. Add seeded local AI opponents through legal engine actions only.
8. Restore the board preview/diagnostic screen using the canonical geometry and art.
9. Complete animation/input coordination for dice, pawns, captures, stacks, turn feedback and reduced-motion/accessibility.

P1 acceptance: widget/navigation tests cover first launch, returning user, setup, human-vs-AI, all local seats, back navigation, and repeated match entry/exit. Full deterministic matches complete without illegal state transitions.

### P2 — persistence and polish

10. Add durable, versioned local snapshots and deterministic replay.
11. Add sound/haptic preferences and lifecycle-safe feedback.
12. Add launcher branding, accessibility semantics, text scaling and viewport acceptance.
13. Run sustained match tests, memory/frame-time checks, and physical Android device acceptance.

P2 acceptance: restart/resume produces the same state as uninterrupted play; no duplicate accepted command; release APK passes real-device gameplay and visual QA.

### P3 — deferred modes and online readiness

14. Only after the four-player Classic local milestone is accepted, implement Team Up as an isolated named rules profile using the same engine.
15. Consider online multiplayer only with an authoritative server design, reconnect semantics, anti-cheat validation and security review.

## Required test matrix

- Domain: all legal/illegal dice and pawn moves; yard entry; exact finish/overshoot; capture on safe/unsafe cells; bonus turn precedence; consecutive sixes; finished-player skip; winner/match completion.
- Board: 52 unique physical cells; four entry offsets; route wrap; connector edges; five private lane cells per player; separate centre finish; 16 independently measured yard sockets; safe-cell mapping.
- Presentation: dice disabled during animation; no double roll; pawn hit targets; shared-cell chooser; capture/finish feedback; active-player and legal-move highlights; no animation-authoritative rule changes.
- Navigation: splash/onboarding; home; setup; match; pause/resume; back navigation; repeated launch/exit.
- AI: deterministic seeded choices; legal move only; no action against stale state; human/AI seat ownership.
- Persistence: schema version, invalid/corrupt snapshot rejection, replay equivalence, command idempotency across restart.
- Device: 360×800, 393×873, 412×915, 800×360; Android physical-device touch alignment, frame pacing, memory, lifecycle and release APK.

## Definition of done for every recovered feature

1. Identify the legacy behaviour and its old tests/docs.
2. Decide whether it is still a product requirement or merely historical code.
3. Implement it in the rebuild's existing module boundaries; do not copy whole legacy classes.
4. Add focused domain/widget/integration regression tests before calling it complete.
5. Run formatting, strict analysis, all Flutter tests, Android integration and APK builds as applicable.
6. Update this plan and `docs/PROJECT_STATUS.md` with commit and CI evidence.
7. Commit directly to `main`; never force-push or overwrite a newer main revision.
8. State separately what is automated, visually inspected, and tested on a physical device.

## Current execution focus

P0 artwork calibration and Classic rule acceptance remain open. P1 onboarding, human/AI setup, seeded legal-action AI, and expanded board diagnostics are implemented. A first local save/resume slice now persists versioned game snapshots, AI seats and seed, and exposes resume/discard on Home; event replay and Android process-recreation acceptance remain open. Next: validate current CI, test background/foreground and process-kill recovery on Android, then close the remaining rule and artwork acceptance gates. Team Up remains deliberately deferred until Classic acceptance.
