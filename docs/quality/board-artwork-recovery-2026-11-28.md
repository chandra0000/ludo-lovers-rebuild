# Recover board-image failure without changing approved artwork

Confirmed gap: MatchBoardArtwork hid overlays and displayed an asset error, but
provided no recovery action. A transient decode/cache failure required leaving
the match. The normal first-frame gate already existed and is preserved.

## Change

The artwork widget now owns only an image retry generation and pending-eviction
flag. Retry evicts that provider, resolves a replacement Image stream and keeps
all board overlays hidden/non-interactive until its decoded frame exists. It does
not reset MatchSession, reroll dice, change rules or alter the source image. A
mounted guard prevents late setState after disposal. Cache-eviction errors leave
the recoverable image path available rather than crashing navigation.

MatchScreen supplies its existing canvas scale. Error text uses bundled Nunito;
the retry control compensates for canvas scaling to retain48 logical-pixel minimum
bounds. System text scaling remains active. Short visible Retry copy has the
semantic label Retry board image; the error is a live region. Very enlarged error
content can scroll within its bounded area. No normal-board pixels, assets,
anchors, hitboxes, profile identity, dice/pawn design or chooser policy change.

## Verification

The injected-image fixture exercises the real GameBoardScaffold/MatchBoardArtwork
components at320x640,360x800,393x873,430x932 and100/130/150/200% actual text scaling,
with system safe-area padding. It asserts decoded-frame readiness,48dp visible
retry bounds, no premature pawn input, one replacement stream for immediate
repeated retry input, successful recovery and disposal during asynchronous
cache eviction. The fixture's pawn is a test input probe, not a second game engine.

The generic capture helper still requires zero unexpected image errors. Only this
negative fixture supplies its exact injected error object/count; an unexpected
error or missing expected error fails. Normal image-load assertions and required
CI screenshots are unchanged. A1x1 synthetic frame is used only to complete the
recovery probe; it is not approved artwork or visual gameplay evidence.

Seventeen focused recovery cases and the final full513-test suite PASS locally.
Strict204-file formatting and fatal-info analysis PASS. Exact-head CI and native
acceptance remain required before merge. Error-state component PNGs under test-artifacts/acceptance
were actually Flutter-rendered with bundled fonts; compact100%/200% examples were
inspected. They are component failure-fixture captures, not installed-app images,
physical-device acceptance or a9.5/10 visual sign-off.

Required forward verification: strict format/analyzer, full suite, approved asset/
board pixel regressions, native builds/checkpoint and normal four-viewport gameplay
recording. The separate default-renderer, physical, signing/store and owner visual
release gates are not cleared by these widget tests. Global dice/AI readiness
orchestration is outside this narrow asset-retry change; board overlay input is
the preserved and verified readiness boundary here.
