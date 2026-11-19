# Royal unified gameplay execution

## Phase 0 baseline and dependency audit

Latest remote main remains `879f2b555c50575c5db066e0ac8bf530271a965a` (#43).
GitHub API verified #54–#66 are still open/unmerged and no newer application work
exists. #65 required workflow 44223326622 is successful; #63 has successful full
checks, Android runtime and installed iOS simulator checks. Fresh local baseline:
414 tests passed. Previous source/artifact receipts are in the Premium V2 report.
Git remote access is unavailable in this workspace; authenticated GitHub API is
used for publishing, with matching tree SHAs and distinct local/source commits.

The implementation follows #66 rather than discarding pending reviewed fixes or
automatically merging them into main. Review dependency graph:
main → #54…#66 → unified scaffold → royal materials/backdrop → player social
controls → final mode/runtime/capture acceptance. All PRs remain unmerged.

Existing authoritative MatchSession, mode profiles/configuration, seeded AI,
persistence, geometry, safe cells, premium pawn painter and gold dice are reused.
No Riverpod game-state layer exists to replace. The legacy parity matrix from
Premium V2 remains valid: Team Up behavior was migrated, Quick is an approved
independent profile, online/rooms/tournament/friends/coins are not working services.
This request is local UI/gameplay productionization, not approval of the online RFC.

## Phase 1 — unified live scaffold

GameBoardScaffold replaces the top-only HUD in the actual MatchScreen. Stable
PlayerSlotResolver uses authoritative participating seats/profiles and domain team
identity. Visual reading order is Orange/Green, then Blue/Magenta; engine order
remains Orange/Green/Magenta/Blue. Missing seats are EMPTY/WAITING, AI uses a robot,
and names remain persisted profile metadata. One shared board transform retains
all artwork/anchors. Centered logo and independently tappable gold die align;
static mode title and visible roll-prompt pill are removed. An accessible legal
pawn chooser remains a 48dp control, rather than shrinking into the status line.

No board, logo or rule-profile modification is included. The original registered
artwork extraction is preserved exactly; no new crop is introduced. Internal
preview mode gates are retained until acceptance. The legacy HUD remains only as
an isolated regression reference; there is one production MatchScreen.

Initial verification: fresh baseline 414/414; scaffold-focused 16/16; exact raw-RGBA
reference-canvas comparison passes with zero changed board pixels at equal scale.
Responsive assertions now check physical quadrant positions separately from engine
turn order and verify logo/dice center alignment. The obsolete Quick title assertion
is replaced with the required logo-only header check; Quick configuration/rematch
assertions remain active. No gameplay regression assertion was removed.

Phase 1 final local gates: all 420 tests passed (137s), 175-file strict format and
fatal-info analysis clean. Repaired old component-type assertions to check the
live scaffold/utility bar; every geometry/pawn anchor assertion remains. Required
four viewport and extended screenshots regenerated; 393×873 actual render
inspected. Native builds/runtime and final visual acceptance remain separate gates.

## Phase 2/3 — royal presentation and reused gameplay materials

RoyalBackdrop covers the entire scaffold including unsafe-area/header/footer
surfaces. Deterministic cached gradient/radial lighting, four vector filigree
corners, warm static bokeh and vignette use no fullscreen blur, timers or particle
controllers. IgnorePointer/ExcludeSemantics keep decoration out of interaction.
A RepaintBoundary caches the background. Static lighting is reduced-motion safe.
RoyalGameHeader preserves the approved logo image with a round presentation,
crown accent and bounded gold glow. Active profile crowns/glass frames retain seat
colors; the centered dice arena clips its soft floor/shadow effects to the HUD.
Existing authoritative gold die tumble/settle, sculpted pawn lighting, cell movement,
stack chooser, captures and reduced-motion lifecycle are reused, not duplicated.

Phase 2/3 gates: 422 full tests pass (115s), fatal-info analysis clean. Background
hit-testing/no-idle-frame tests pass with reduced motion on/off. The exact board
pixel test also wraps the unified surface in RoyalBackdrop. All ten responsive
captures regenerate; actual compact 320×640 lighting inspected. No repeated idle
animation controller or full-screen image allocation is added. Shadows/lighting
are presentation-only; physical GPU/60fps acceptance is still unavailable.

## Phase 4 — per-profile local social interaction

Every participating profile has 28dp chat/emoji icons in two independent 48dp
controls; inactive slots have none. The shared emoji entry is removed. The footer
retains Local Chat, Settings and the conditional accessible legal-pawn chooser.
Per-profile actions capture the originating seat; local presets/reactions never
follow a later active-player change. SocialOverlayCoordinator bounds feedback to
one bubble/timer per seat and replaces, expires, clears on rematch and cancels on
disposal. Floating bubbles remain inside avatar-card bounds, with reduced-motion
alternatives and live semantics. No message is sent online or represented as a
remote delivery. The existing chat sheet now has presets, sender naming and an
intentional scroll surface for compact/enlarged-text/keyboard constraints.

AI state is sourced from actual turn presentation, not a fake progress loop;
robot cards expose thinking semantics and the live status line shows AI thinking.
Team badges use domain team identity and team score capacity derives from actual
pawn lists rather than a hardcoded initial score. Names remain above square
avatars; inline active crowns cannot overlap social controls.

Verification: all 430 tests pass (123s); strict 183-file format and fatal-info
analysis clean. Eight new social regressions cover four phone sizes, 48dp targets,
no board overlap, attribution without a gameplay command, inactive seats, timer
replacement/expiry/disposal and compact 150% text/keyboard chat. Actual 320×640
final social/HUD capture inspected. Board pixel and geometry regressions pass.

## Phase 5 — four local presentation configurations

Mode selection exposes explicit FFA, 1v1, VS Computer and Team-Up launch presets.
These are setup defaults over the same ModeRegistry/MatchConfiguration and shared
MatchSession, not four new engines. FFA keeps compatibility defaults; 1v1 selects
Classic's approved two-seat configuration; VS Computer initializes the existing
human/AI setup and keeps at least one bot; Team-Up uses team-up@1. The ordinary
Classic/Quick/configuration cards remain present. No profile or turn policy changes.
Preview release gates cannot be bypassed through a preset. True 1v1 slot colors
come from the authoritative configured roster, not a second UI mapping.

Phase 5 verification: 435 full tests passed, strict format and fatal-info analysis
clean. Five new preset tests verify real saved mode/seat/bot configuration and
public availability gates; shared local-mode navigation still passes. No online
rooms, friends, tournament or coin service is claimed. Approved Team Up and Quick
rules are reused from the preceding verified migration, not copied again.

## Phase 6 — final software/native acceptance expansion

Seven additional real Flutter PNGs cover FFA, true 1v1 placeholders, computer
robots, Team-Up, the emoji picker, avatar-centered bubble and local chat presets.
The capture suite reuses the production app theme. CI verifies all 36 required
software PNGs, including the earlier home/setup/roll/move/capture/win/rematch and
responsive sets. Header screenshot review exposed a crown stretched to logo
width; a bounded 16dp square constraint fixes it and a regression test protects it.
Explicit native emoji fallback and an optional installed OS emoji face in tests
prevent software capture tofu without adding/replacing runtime assets.

Installed integration uses the SDK extended driver screenshot callback, checked
against the pinned Flutter3.35.7 source. Host writes and full PNG validation are
bounded/required. Android surface conversion is scoped to each test with the SDK's
automatic teardown reversion. Captures are deliberately not performance traces.
Eight emulator/simulator PNGs are required: FFA, Classic, Quick, Team-Up, computer,
emoji picker, local bubble and local chat. Platform jobs upload them separately
from software widget PNGs. Native results remain pending until actual CI completes.

Profile APKs now explicitly enable the internal modes for concrete owner review
and physical profiling, uploaded as `ludo-internal-modes-profile-apks`. Release
APKs/AAB and normal debug acceptance APK keep default public gates. Profile
artifacts are QA-only/debug-signed, not production-release acceptance. No extra
native build is duplicated solely to create this review variant.

### Final hardening root causes

The new active-AI teardown test initially failed on a pending 450ms timer. Existing
MatchAiScheduler used a generation-guarded Future.delayed: it blocked stale game
commands but could not cancel the underlying timer. It now uses a cancellable
Timer with the same delay, generation checks and authoritative callback. Cancel/
restart/dispose remove the actual timer; no AI strategy, dice or rule change.
The scheduler/active-thinking focused regression passes without flushing or hiding
that timer. The existing profile-visibility calibration option remains honored.
BoardGeometry.visualApprovalPending remains true; no gameplay-readiness approval
or public preview promotion is inferred from test success.

HUD profile rows explicitly clip decorative effects to their independent regions.
A second pixel regression compares composited full-screen board pixels while
turn glow moves to a bottom profile on a compact safe-area viewport. It passes
alongside the exact old/new reference-canvas check. This guards actual composition,
not only source-file hashes or isolated board paint.

Phase 6 final local source gates: all 445 tests passed (137s), strict formatting of
188 Dart files via `dart format --output=none --set-exit-if-changed .`, and clean
fatal-info analysis. All 36 required software PNGs decode/verify. YAML and both
platform scripts parse. Native fixtures include bounded asset readiness, 15-second
screenshot transactions and three-minute per-test limits; workflow timeouts are
not increased. Native captures and new build artifacts await CI on this source.
No approved asset or pure domain/application file changed in this royal program.
