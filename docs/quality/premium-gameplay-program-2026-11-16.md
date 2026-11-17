# Premium gameplay program — verified investigation and delivery ledger

## Phase A baseline and authority

Latest main audited: `5dd35fb39efdbb22b50c1a549b41350e9b9f0e90` (only the prior
handoff document differs from application baseline `4089a628ef528f55be35c5e9472ed63d08bfebe1`).
Implementation baseline: draft PR #46, `d2054308a0b820e9b8757637ccf7b0074ddbb37b`.
It is a live `MatchScreen` implementation, not a demonstration screen. Its
[foundation checks](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196713)
and [Android/iOS builds](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/43802196676)
are successful; 298 tests passed before this increment.

PR #45 is already integrated into #43 as `a1ef5846d2a5f4fe3f66b1e9ee344c93c4e626bb`.
Its restoration fix and pure storage boundary are retained. #42's pawn code/tests
are already present byte-for-byte; do not duplicate it. #40's halo, accessible
pawn-choice intent and 48dp target concerns have been reconciled in #44/#46; its
old overlay placement must not overwrite the current layout. #39 is an experimental
static marker harness, not proof that Flame is faster. #43 and #46 remain draft.

The current owner instruction **prohibits automatic PR merging**, superseding the
previous technical-merge permission. All work in this program uses focused stacked
PRs; no remote PR is merged automatically. Source of truth is the rebuild. Preserve
MatchSession, default `ludo-lovers-current@1`, opt-in `classic@1`, source assets,
BoardGeometry, turn order and portrait composition. Notion's early Flame-first
technology note and outdated merge sequence do not override the current explicit
instruction to retain Flutter unless measured evidence justifies a change.

Relevant sources reviewed: current architecture/decisions/session/geometry docs,
GitHub open work and historical failing responsive CI, existing Notion Project Hub
and release/visual notes, and actual legacy source/tests at
`ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`. The legacy checkout is reference-only.
Prior cancelled workflows remain failures of acceptance, not successes. The
historical #43 capture timeout was repaired in #44; new baseline workflows pass.

Live source boundaries:
- `features/match/match_screen.dart`: scene and presentation orchestration.
- `game/application/match_session.dart`: authoritative command acceptance.
- `game/domain/board_geometry.dart`: unchanged route, lanes, yards and safe cells.
- `game/domain/persistence/saved_match.dart`: pure snapshot DTO/codec.
- `game/infrastructure/persistence/`: platform storage.

## Phase B — stable identity and editable names

### Reported color changes: reproduced causes, not a guessed engine race

Two concrete display mismatches were verified against BoardGeometry and the actual
bundled portrait images:

1. The Magenta profile was at bottom-left and Blue at bottom-right, opposite their
   authoritative yards. Orange/Green were correct. A regression on the unchanged
   baseline fails: `magenta HUD must sit beside its own yard`.
2. Magenta was assigned `avatar_bob.webp`, which includes a blue ring, while Blue
   was assigned `avatar_emma.webp`, which includes a magenta ring. Those exact
   immutable images were inspected. The HUD association now matches the ring and
   authoritative seat; image bytes, artwork, yard sockets and pawns are unchanged.
3. The inner avatar border changed to gold on activation. It now retains the seat
   accent; the outer card/arrow provides the permitted gold active-turn indicator.

No mutation of PlayerColor, enum turn order or engine seat identity was found.
The corrected display contract is Orange top-left, Green top-right, Magenta
bottom-right and Blue bottom-left. Profiles are captured once in match state,
keyed by color and stable ID, ordered by the authoritative turn order, and saved.
Tests rotate all active colors with reversed profile lists and verify identity,
portrait mapping and stable avatar border colors. No index-based or name-based
actor identity is introduced.

### Names, setup preferences and restoration

- Editable human names are available in live setup under EDIT PLAYER NAMES.
  Defaults remain color names; AI gets a labelled default Bot name and indicator.
- Existing engine always has four seats. Two/three human selections fill the
  remaining seats with AI; they are not advertised as a new two-seat rules mode.
- Names are trimmed and internal Unicode whitespace collapsed. Limit: **20 Unicode
  graphemes**. Emoji/combining characters and non-Latin scripts are supported.
  A secondary 512 UTF-16-code-unit limit bounds pathological combining sequences.
- Reject blank/invisible-only text, C0/C1 controls, bidi formatting/spoof controls,
  zero-width space, soft hyphen and known blank fillers. Preserve legitimate emoji
  variation selectors and language/emoji joiners when visible text exists.
- Validation is visible inline; starting with invalid human input opens/scrolls to
  the error. Keyboard focus is dismissed before a valid game starts. Preferences
  are best-effort; save failure gives feedback without blocking local play.
- Duplicate names are allowed. Visible seat numbers and full color/seat semantics
  disambiguate them. Names never become player IDs, command IDs or actor IDs.
- Preferred human names use a separate versioned preference key. Local match
  schema **v3** persists names, stable IDs, colors, roles and avatar metadata.
  Schema v1/v2 still restore their exact engine state and reconstruct stable
  default identities. Game snapshot schema/rule profiles are unchanged.
- Rosters are immutable and validate four unique colors/IDs and correct AI roles.
  Restart retains the roster; Home resume passes the saved roster into the live
  match; winner status displays the entered name plus color when customized.
- `characters` is an explicit pure Dart dependency. The architecture guard permits
  exactly that Unicode utility while continuing to reject Flutter/Flame/storage
  and other package dependencies in domain/application code.

Local verification: **313 tests passed** in 88 seconds; strict analysis has no
issues. Tests cover Unicode/grapheme limits, invisible input, duplicate names,
roster corruption, v1/v2 migrations, preference persistence, editable setup,
restart/Home resume, winner naming, two/three-human roles and all active turns.
Screenshots use deterministic named human profiles at all four required sizes.
Remote CI conclusions and source commit are recorded in the PR, not inferred here.

## Verified legacy feature inventory

This matrix records actual source/test presence, not a claim that legacy tests or
physical acceptance were executed in this program. Legacy dependencies and roadmap
notes alone do not count as implemented features. `P0/P1/P2` indicate recommended
priority, not proof of product approval.

| Feature | Legacy implementation | Rebuild implementation | Missing functionality | Architecture compatibility | Coverage evidence | Priority / decision |
| --- | --- | --- | --- | --- | --- | --- |
| Classic/local rules | `LocalGameFactory`, `LudoRuleProfile`, path engine; provisional route gate | Pure `LudoGame` + MatchSession, compatibility default/Classic opt-in | Owner Classic/source acceptance | Behavior references only; never copy engine | Both repositories have rule/route tests; rebuild suite executed | P0 preserve current profiles |
| Two-/three-/four-player | Factory permits 2–4 selected seats; live two-color picker | Four seats, 1–4 humans with remaining AI | True variable-seat engine mode | Requires explicit seat/rule policy changes | Legacy factory/navigation tests; rebuild role tests | P1 defer new seat-count rules |
| Quick mode | No executable mode found | No implementation/availability claim | Approved rules and mode | Needs separate versioned profile | No mode-specific tests | P2 blocked on specification |
| Team Up | Real TeamUpRules + engine arrival/departure priority and team victory | #23 contains plan/session work; setup disabled | Mode/domain/snapshot/UI integration | Port behavior tests after approval, not architecture | Legacy team_up_engine/rules tests; rebuild plan only | P1 separate approved program |
| Tournament | No executable progression/bracket found | Not implemented | Approved progression spec | Separate app state, not new movement engine | No implementation tests | P2 blocked on specification |
| AI | Local controller/engine policy; no verified difficulty selector | Seeded legal-only easy/medium/hard | Physical turn/soak acceptance | Existing rebuild policy retained | Seeded AI, legality and lifecycle tests pass | P0 preserve/test |
| Private rooms | No working service/route found | No online service | Authoritative backend/reconnect | Future authenticated transport | None proving a service | P2 do not fake availability |
| Friends/buddies | No implementation found | No implementation | Identity/social backend | Future separate subsystem | None proving a service | P2 defer |
| Emoji reactions | Board reaction dock/local feedback | Working local picker/toast/chat callback | Online transport intentionally absent | Existing presentation callbacks | Rebuild local reaction/widget tests pass | P1 retain/refine local behavior |
| Chat | Button shows “Online mode is not enabled” | Working local-device chat sheet | Actual online service | Keep local clearly labelled | Local chat tests pass | P1 retain; no online claim |
| Rematch/restart | Fresh local setup/controller | Live restart/PLAY AGAIN; names now retained | Explicit profile-preservation regression/device soak | Reuse MatchSession and orchestration | Restart and lifecycle tests; new name flow | P0 harden in Phase E |
| Player customization | Selected colors; no editable-name UI found | New Phase B editable human names; stable default portraits | Custom-avatar UI not implemented | Presentation metadata, no rule changes | New identity/name persistence tests | P0 implement names; defer avatar service |
| Match stats/history | No durable statistics/history found | Current winner only | Versioned history/deduplication policy | Needs stable match record contract | No history suite | P2 defer rather than invent counters |
| Onboarding | Screen exists but current root bypasses it | Live first-launch onboarding with preferences | Device UX acceptance | Already integrated | Rebuild onboarding tests pass | P1 retain |
| Audio/haptics | Platform sounds/haptics; sound flag hardcoded true | Existing dice/invalid haptics; no user controls | Persistent controls and safe async failures | Local feedback adapter, no game rules | Existing dice/lifecycle tests | P1 implement bounded controls |
| Settings | No general user settings UI found | No game feedback settings UI yet | User controls for sound/haptics/motion | Local versioned preferences | Not implemented | P1 implement essential controls |
| Reduced motion | No explicit disableAnimations handling found in legacy source | Existing motion-aware dice/landing/timing | User preference + mid-animation changes | Presentation-only policy | Existing animation/timing tests | P1 refine |
| Accessibility | Semantics/hit tests in legacy | Semantics, legal chooser, transformed 48dp bounds, 150% text | TalkBack/device/quantitative contrast acceptance | Shared engine-legal actions | Existing and new widget checks pass | P0 preserve/harden |
| Persistence | shared_preferences dependency exists; no durable match save/restore use found | Versioned saved match with serialized writes, resume; new roster v3 | Physical process-kill acceptance | Existing adapter/DTO | Codec/store/recovery tests pass | P0 preserve/migrate |
| Exit confirmation | No implemented confirmation flow verified | Direct exit/navigation currently | Clear confirm/cancel/save feedback | Local navigation/dialog boundary | Existing navigation tests | P1 implement safe local UX |

Useful migrations selected for later phases are platform-safe feedback with user
controls, reduced-motion handling and clear exit confirmation. They will use the
rebuild's live widgets and adapters, not legacy controllers or dependencies.
No new online service, economy or unapproved mode is included.

## Remaining phases and acceptance

A investigation/baseline is verified. B implementation is locally tested and awaits
its published CI and visual acceptance. C pawn/dice/feedback, D stars/responsive,
E gameplay/lifecycle, F selected legacy UX and G performance/release review remain
sequential work. Physical Android/iOS devices and production signing credentials
are unavailable; device-only benchmarks and release acceptance must remain open.
All new PRs remain unmerged for owner review. No new final quality score is assigned
from task completion alone.

## Phase C — materials and feedback

The live die retains its accepted engine value through anticipation, tumble and
settle; gold face lighting, bevels and resting perspective reveal cube depth.
All six dominant faces are tested. Glass pawns retain their coordinates and
silhouette, with controlled highlights, repaint boundaries and finite landing
bounce. Existing cell-by-cell movement follows authoritative geometry.

The live More menu offers independently persisted sound, haptic and reduced-motion
controls. Platform feedback follows accepted commands and handles platform errors.
System reduced motion also applies; enabling it during a roll completes the same
accepted result exactly once. No independent randomness or audio engine added.

Verification: 317 local tests passed; strict formatting and fatal-info analysis
passed. Actual 393×873 screenshot inspected: gold cube, square named profiles and
full board visible. Four required captures exist. Owner visual acceptance and
physical-device performance remain open; no measured performance gain is claimed.
Phase B PR #48 has all required CI checks green. New PRs remain unmerged.

## Phase D — safe cells and adaptive acceptance

The approved extracted board already contains gold stars at the four non-entry
safe cells. The previous overlay painted duplicate icons. Removed only duplicate
paint; eight read-only semantic anchors now derive from `safeTrackCells`, including
four entries. Tests assert exact rule sets, positions, no extra icons and ignored
pointer input. Artwork, geometry, pawn coordinates and safe rules are unchanged.

Responsive capture now covers the four mandatory viewports plus 320×568/375×667
compact phones, 393×873 at DPR3 with 59/34 insets, 440×956 at DPR3 with 62/34
insets, 360×780 at DPR2.75 with 32/24 insets, and 600×1024 at DPR2. Tests provide
both real logical padding and physical view padding. They check square avatars,
names above avatars, board/profile separation, safe areas and 48dp controls.
The artifact verifier requires all ten PNGs. Actual compact 320×568 capture was
visually inspected: full board, four readable profiles and accessible controls.
These configurations model logical displays, not physical-device acceptance.

App launch requests portraitUp, with a platform-channel regression test. Modern
large-screen platform orientation policy may override this request; adaptive
rendering remains necessary. No platform behavior is inferred from a mock test.

## Phase E — restart and lifecycle hardening

Reproduced three failing regressions before the fix: Classic restart and rematch
silently selected the default rule profile; a stale human roll callback consumed
randomness while backgrounded. Fresh MatchSession creation now preserves the
current versioned rule profile, and command entry points guard resumed lifecycle
before randomness or transitions. UI roll availability rebuilds on pause/resume.
Rules, turn order and engine transitions are unchanged.

The serialized persistence controller exposes the latest completed save outcome
(null before completion). Failures still do not poison later writes. This supports
accurate exit feedback without exposing storage implementation to the engine.
A pre-existing reduced-motion test's redundant tap on an already moved, inactive
pawn was replaced with assertions on persisted progress and cleared dice; its
missed-hit warning no longer masks whether the first move actually happened.

Focused verification: 26 tests passed, including pre-fix reproduction coverage,
restored human turns, ordered saves and gameplay presentation.

## Phase F — safe local exit flow

Toolbar, More menu and system back share a PopScope-guarded confirmation. Opening
it cancels scheduled AI/automatic resolution and blocks stale command callbacks.
Cancel resumes the accepted dice result or AI schedule without rerolling. In-flight
pawn presentation may finish; it does not create additional engine transitions.
Repeated callbacks cannot stack prompts.

The prompt awaits the serialized save and reports its actual success or failure.
A three-second storage deadline prevents a broken platform adapter from trapping
navigation; queued writes may still finish, but recovery is never promised early.
Stay and Leave are explicit actions. Confirmed navigation waits for PopScope's
canPop update before popping the route.

Tests cover accepted-roll preservation, confirm/save/return, menu/system back,
repeated callbacks, failed and slow saves, pending movement, and AI pause/recovery.
Existing repeated-navigation tests now confirm explicitly. Phase C's feedback
preferences and this flow complete the selected safe local UX work from the
verified legacy inventory. No legacy engine, online service, economy, statistics
policy or unapproved mode was copied.
