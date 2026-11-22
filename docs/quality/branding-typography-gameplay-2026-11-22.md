# Branding, typography and gameplay presentation

Status: IMPLEMENTED, AWAITING COMPLETE VERIFICATION. This ledger will be updated
with exact tested commits and CI artifacts. No release or visual gate is cleared.

## Baseline and authority

Notion hub section **Current branding, typography and gameplay QA update**, including
**Updated Codex Cloud master prompt**, was read before editing. It supersedes old
Flame-only and fixed-delay startup notes. No AGENTS.md exists in the checked
repository/workspace parents. Architecture, development/testing and commercial
release gates remain authoritative.

Main remains879f2b555c50575c5db066e0ac8bf530271a965a; #73–#75 are open/unmerged.
Source is #75 e6a6fa785a243c0b410e43228445ec6bfb12af5f, not older main. The
application baseline is ad16fed5e9327c4211c6916c0b8e4b7c4f723867. New branch:
feat/branding-typography-gameplay-qa. Review after #73 → #74 → #75; do not merge
automatically. Historical recording SHA256 remains
405a2c00169043e8bf422e75a25d380f134cfeee25c77e0dd21eb552f33d21c5.

## Exact typography

| Element | Family / weight | Starting logical size |
| --- | --- | --- |
| Screen titles / Victory! | Cinzel700 | 28 (26–32 approved range) |
| Buttons | Nunito800 | 16 (16–18 range) |
| Player names above square avatars | Nunito700 | 15 (15–17 range) |
| Gameplay status | Nunito600 | 15 (14–16 range) |
| Settings/instructions/chat | Nunito400 | 15 (14–16 range) |

Fonts and OFL licenses are local assets with explicit weight registrations. No
runtime font fetches. AppTypography and ThemeData provide semantic defaults.
Warm gold#F4D58D headings / ivory#FFF4DF functional text are contrast-tested on
actual dark surfaces. Platform script/emoji fallbacks remain separate from
MaterialIcons; screenshot helpers load bundled fonts and SDK icons explicitly.
System TextScaler is not capped. At enlarged text, utility controls become
labeled/tooled semantic icons with 48dp targets; profiles reduce decorative avatar
space before the board. Full names remain accessible despite visible truncation.

## Native branding

Canonical2048×2048 RGB opaque logo is unchanged. Reproduce icon/splash resources:

```bash
cd apps/mobile
# Generation only needs Pillow13.0.0. Committed output is used in CI.
python3 tool/generate_branding.py --generate
flutter create --platforms=android,ios --project-name=ludo_lovers --org=com.ludolovers .
python3 tool/generate_branding.py --apply
```

Every CI scaffolding step applies the committed native_branding overlay afterwards;
--apply uses Python stdlib plus macOS sips for the full-resolution marketing PNG. Android legacy density PNGs, adaptive foreground
on royal background and API33 monochrome derivative are generated. Foreground
logo square uses42% of the108dp layer, wholly within the central safe circle.
Full-color logo is resized/letterboxed only. The monochrome derivative is used
only by themed launchers. iOS AppIcon includes iPhone/iPad/1024 marketing sizes,
all opaque. The 1024px marketing PNG is generated from the canonical opaque logo
by macOS sips when applying the overlay (full local generation uses Pillow).
Installed label is Ludo Lovers; identifiers are untouched.

Android legacy/Android12+ and iOS launch use the same royal#160B28 background and
proportional logo. Flutter splash uses that logo/background without animation.
Preferences readiness replaces the old1800ms timer; initialization is bounded8s,
errors show retry, navigation waits for foreground and disposal invalidates pending
completion. No artificial branding duration. Onboarding and saved-match behavior
are retained; real process-death acceptance remains separate.

## Video findings and corrections

Confirmed: 11/10px competing status lines were hard to read. The new15px semantic
status combines the action and player name; authoritative turn identity remains
in live-region semantics. Moving-player identity follows the animation's accepted
plan rather than mislabeling travel with the already-advanced next player.

Confirmed: the PopupMenu pawn chooser overlays the bottom HUD. One scrollable,
safe-area modal sheet now serves utility and stacked-pawn selection, shows all
four identities, disabled illegal choices and legal48dp+ targets. It dispatches
the same authoritative move handler.

Dice investigation: independent face planes had22%-radius rounded corners,
leaving visible corner gaps during rotation. Narrower6% bevel corners join the
same rigid cube more cleanly, retaining gold gradients, pips and authoritative
orientation. Native motion review remains required before visual approval.

Pawn visibility is a design refinement: stronger contact shadow and dark
under-outline on the same existing path; shape/centers/footprint/hit testing and
BoardGeometry are unchanged.

Confirmed fixture issue: mountFixture deliberately pumped an empty SizedBox for
200ms between scenarios. The intermediate blank unmount is removed. Scenario
replacement is still disclosed. This is not proof of a production startup bug.
The recording workflow separately captures the normal entrypoint's launcher,
cold native/Flutter startup, home and setup before switching to the integration
APK for deterministic gameplay. No footage is edited or interpolated.

## Validation and open gates

Pending final results: full format/analyze/tests, four viewport and200% captures,
Android builds and native recording, iOS simulator, launcher/native splash review.
The previous software/debug recording's9.16fps average /20.67fps active cadence
are historical, not improved performance measurements. Default GPU failure is
still unresolved. Physical Android/iOS, process-death/soak/performance, signing,
store configuration and owner visual approval remain separate incomplete gates.

## Native investigation follow-up

First source44b135df run45011467680 passed all four installed scenarios and all
native screenshots. The unedited95.743711s MP4 failed the unchanged45–95s duration
gate. Added normal startup and test APK installation made the old final13s idle
hold excessive. The follow-up shortens only this QA idle hold, never production
animations, and adds an actual home/background/warm-return assertion.

Frame inspection separated three transitions: a0.65s empty royal first Flutter
frame during normal startup; a0.74s black interval during the disclosed APK
replacement; and a3.31s empty integration-test surface while attaching the driver.
Startup now holds the native branded first frame until destination readiness,
with zero extra route animation; timeout/error/disposal always release the hold.
The QA host returns to the actual launcher before APK replacement, and the
recording-only integration entry paints LudoLoversApp while the driver attaches.
These changes require new native capture; no footage is edited to hide intervals.

A new200% Team-Up regression reproduced score-strip and wrapped badge overflows.
The follow-up derives strip height from TextScaler, keeps scores/identity in
semantics, removes redundant teammate-name repetition in the enlarged strip and
uses compact A/B labels. All teammate profiles remain visible. No scoring/rule
logic changes. Source44b135df's normal-size native Team-Up test already passed;
this correction addresses enlarged-text presentation.

The first default-renderer attempt45012211468 did not run the app: Maven returned
HTTP429 for Kotlin2.0.21 POMs. It is not GPU runtime evidence. Checkpoint/recording
now reuse the existing pinned Gradle cache rather than repeatedly downloading
those same artifacts. No dependency version or timeout is relaxed.

iOS source44b135df compiled both normal and integration apps, then the console-
attached simctl launch never acknowledged startup; its logs contained only a
uid501 lookup warning and no VM service. The follow-up separates a30s non-console
launch acknowledgement from the existing60s VM readiness check, retaining unified
logs. The underlying simulator launch cause is not established as an app defect
or infrastructure defect. Installed iOS verification remains pending a new run.

Source014bd8cb's software native job45013353444 reproduced a Flutter frame-timing
assertion after the widget-owned frame hold changed sendFramesToEngine during
render finalization. A phase-recording binding regression fails on that timing.
The correction moves cold deferral before runApp into StartupFrameGate; Splash
only reports first-view readiness/error/disposal, and the gate releases once in
a post-frame callback. Integration tests do not own production bootstrap holds.
No exception is filtered or suppressed.

The no-console iOS launch now acknowledges the app, attaches the driver and saves
all eight native screenshots. Its first navigation test reports an outstanding
SemanticsHandle at teardown. The next harness logs native accessibility activation
and handle counts to distinguish platform-owned activation from a real leak;
semantics and leak checks remain enabled. Native iOS acceptance is still pending.
The cached default Android renderer reproduced driver/ADB/QEMU loss after first
FFA capture; no kernel OOM/native crash signature was captured. The cause remains
unproven, with viewport1080×1920 versus recording360×800 also differing. Do not
claim a controlled renderer-only comparison or production GPU acceptance.
