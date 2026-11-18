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
