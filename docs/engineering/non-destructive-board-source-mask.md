# Experiment: board-only mask from the canonical full-glass reference

**Status:** Preview/calibration only; disabled in normal builds until visual approval. This experiment is independent from the event-driven result projector in PR #28.

## Problem and evidence

The approved 810×1440 `assets/images/board/ludo_board_glass.webp` includes four fixed player portraits/names, online status, the board, a golden decorative die and the lower controls. The current default match screen loads `assets/images/board/extracted/board_exact.webp`, whose crop coordinates were measured against an 864×1536 derivative. Even if those two images share a 9:16 aspect ratio, their *board pixels* should not be assumed identical.

The opt-in `LUDO_APPROVED_ART` full-screen preview renders the entire image but duplicates a live die on top of the baked die. It is **not a safe production UI** without cleaned static art.

## Implemented temporary alternative

`CanonicalBoardSourceMask` uses the original approved WebP as the static source, and clips to the board-only region **at render time**, leaving the file bytes untouched. All four player identity badges, animated die, turn label, Chat and More remain live Flutter widgets. The rest of the portrait stage is dark to avoid showing baked names or dice.

This lets us compare the unmodified original board against the extracted board in real screenshot tests, without introducing another independently exported crop.

- Preview flag: `--dart-define=LUDO_CANONICAL_BOARD_MASK=true`.
- Default remains **false**. The former board-only composition is unchanged until owner approval.
- Stage: 576×1024. Clipped board limits initially match `MatchBoardArtwork`: left `15/864*576`, top `307/1536*1024`, width `835/864*576`, height `851/1536*1024`.
- Original source: 810×1440. These are *provisional* visual clip measurements, not logical track coordinates. All existing `BoardGeometry` pawn anchors, 52 track cells, four safe entry markers, home lanes and engine rules are preserved.
- CI visual capture: `test-artifacts/canonical-board-mask-393x873.png`. Compare side-by-side against default `match-screen-393x873.png` and full-art `approved-artwork-preview-393x873.png`.

## What this does NOT solve

- The standalone original image is still decoded even though only the board region is displayed; this may require more RAM/GPU bandwidth than a dedicated optimized board plate.
- The mask may slightly include board-frame pixels from the original whose boundaries differ from the previous extracted crop. Owner screenshot calibration is required.
- It does not reproduce the fixed entire portrait. A production UI requires a **clean, approved static derivative** (background + board + gold decorative frames), independent live player profiles and a single animated authoritative die.
- It does not prove the game is ready for Play Store release; device, performance, legal and signed-AAB gates remain outstanding.

## Visual acceptance / go-no-go

1. Inspect the 393×873 masked screenshot next to the existing extracted-board screenshot at native pixel resolution.
2. Confirm all board edges, gold glow and central star are preserved without baked portrait/names/dice intruding.
3. Compare pawn centres for all four yard corners, 8 safe cells, 20 home-lane cells and 52 shared-track anchors. Require <=2 *physical* pixels deviation on sampled real-device screen captures.
4. Test 360×800, 393×873 and 412×915 portrait dimensions with accessible touch targets. Board stage must be uniformly scaled; no stretching or uncontrolled crop.
5. Profile memory and frame time on physical Android. If masked full-image decoding is too expensive, create a reviewed, deduplicated and optimized static plate derived from the source.
6. Keep `LUDO_CANONICAL_BOARD_MASK` disabled until visual acceptance; rollback is switching it off.

See the [commercial-readiness roadmap](https://app.notion.com/p/417d7b2be1cc81f08f6afbd850391a3a) and [Phase 1 design assets contract](../assets/artwork-and-assets.md).
