# Approved glass artwork integration — staged implementation

**Status:** Feature-flagged visual preview. **Not approved for production use.**

**Stacked on:** Phase 1 controller PR #24 (`refactor/phase1-match-command-controller`). This follow-up does not change the deterministic match engine, command identities, player turns, safe squares, board routes, AI or persistence.

## Reference and source-of-truth

- The **immutable user-approved** image is `apps/mobile/assets/images/board/ludo_board_glass.webp` (810×1440, 9:16).
- The image is a **complete** match composition containing logo, portrait art, a Ludo board, a decorative die and baked player/turn labels. It is not a plain board texture.
- `assets/images/board/extracted/board_exact.webp` is a **derived board-only reference** used by the previous runtime view; it is not the approved entire composition.
- Never crop, distort, recolor, replace, regenerate or silently substitute the canonical original. A production-friendly, cleaned static plate must be explicitly approved as a derivative before public release.

## Code and rollout contract

- `approved_artwork_geometry.dart`: immutable source-to-canvas mapping and measured UI slots. Logical rules and 52-cell route remain in `BoardGeometry`, including the artwork-specific diagonal connectors.
- `approved_reference_plate.dart`: exact full 9:16 reference background, `RepaintBoundary`, proportional decode width, and an explicit asset-failure state.
- `approved_artwork_overlays.dart`: live name, bot/connection and turn text; transparent, accessible actions over baked Chat/More artwork.
- `MatchScreen.useApprovedArtwork`: defaults to `false`. Enable it for preview with `--dart-define=LUDO_APPROVED_ART=true`, or explicitly override the constructor in tests. This is intentionally a **visual flag only**.
- The existing `MatchBoardViewport` keeps the **576×1024** coordinate system and uses one uniform outer scale. Tall-screen side/bottom padding is filled by the surrounding dark background, never by nonuniform stretching.
- Pawns continue using `BoardGeometry` measured anchors and existing `PawnAnimator`. The die still shows the `MatchSession`-accepted value; roll visuals do not generate dice values.
- Only the presentation is switchable. Do **not** version game state, migrate save data or loosen rule tests to enable the preview.

## Known preview limitations — release blockers

The source already contains **baked** portraits, player names, connection labels, a 3D decorative die and a turn label.

- The temporary live name/status patches currently cover only baked text; the baked **portraits** are still fixed placeholders rather than real account/seat avatars.
- The interactive die overlays the source's decorative 3D die. These elements cannot be made truly pixel-perfect until the approved static derivative removes the baked die while retaining its glass/gold frame and surrounding art.
- The temporary live status/name cover-up rectangles are functional but do not yet constitute designer-approved pixel-perfect parity.
- This preview must **not** be enabled in public release. Obtain owner approval for a clean static plate and matching dynamic masks, then replace the preview plate and refine overlay positions in a separate reviewable follow-up.
- Launcher icon generation, legal disclosures, privacy review, crash-free device validation, packaging/signing, store assets, and release testing are outside this PR.

## Implementation milestones

1. [x] Immutable approved source and separately guarded preview path.
2. [x] Source-to-design coordinates, nominal 15×15 calibration guides and uniform-scale unit tests.
3. [x] Full composition display, dynamic labels, transparent Chat/More interaction and widget tests.
4. [ ] Owner-approved **clean static derivative** that removes baked dynamic elements without touching the original.
5. [ ] Align all four *live* portrait/identity badges, animated die, turn indicator and menu surfaces to the approved static frame.
6. [ ] Golden snapshots of 576×1024 stage and portrait 360×800, 393×873, 412×915 screens with controlled fonts and test state.
7. [ ] Automated 52 route + home/yard geometry verification; sampled pawn centres <=2 physical px on real devices.
8. [ ] Touch areas >=44×44 logical px after stage scale; verify on target phones with non-default accessibility settings.
9. [ ] Profile/release APK performance and memory profiling across repeated match entry/exit; confirm reduced motion behavior.
10. [ ] Owner-reviewed screenshots and physical 6.1–6.9-inch Android phone acceptance, then decide feature flag promotion.

## Recommended acceptance matrix

| Gate | Pass condition |
|---|---|
| Existing gameplay tests | No regressions in dice, moves, capture, extra turns, win, restart, AI, persistence and lifecycle |
| Art source | Canonical WebP retained unchanged; all 810×1440 content visible at uniform aspect ratio |
| Geometry | 52 shared tiles, 20 lane anchors, 16 yard sockets, four diagonal transitions and centre retained |
| Portrait fit | 360×800, 393×873 and 412×915 show no crop or covered controls |
| Screenshot parity | Approved plate/HUD golden differs only in authorised dynamic regions |
| Interaction | Chat/More/dice remain tappable and properly announced; no accidental pawn taps |
| Device quality | No black/blank screen, no uncaught image failure, measured movement alignment, smooth animation and memory stability |
| Release | Production-ready static plate approved and final APK/AAB signed and verified on real Android devices |

## Rollback

Switch off `LUDO_APPROVED_ART` without changing snapshots, rules or controller boundaries. Preserve old board-only code and its assets until release acceptance is signed off.

## Relevant references

- [Artwork and assets](../assets/artwork-and-assets.md)
- [Device acceptance](../DEVICE_ACCEPTANCE_AND_PERFORMANCE.md)
- [Flutter SafeArea and MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery)
- [Flutter image caching](https://api.flutter.dev/flutter/widgets/Image/Image.asset.html)
- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter golden test matcher](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
- [Phase 1 PR #24](https://github.com/chandra0000/ludo-lovers-rebuild/pull/24)
