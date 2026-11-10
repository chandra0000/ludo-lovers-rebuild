# Artwork and asset contract

## User-supplied canonical assets

The user intends to provide only two source images for the first milestone:

| Purpose | Canonical repository path | Status |
|---|---|---|
| Board artwork | `apps/mobile/assets/images/board/ludo_board_glass.webp` | Awaiting user upload/verification |
| App launcher icon | `apps/mobile/assets/images/branding/ludo_lovers_icon.webp` | Awaiting user upload/verification |

The app icon is used for Android launcher branding, not as an in-game board layer.

## Preservation requirements

- Treat the supplied source artwork as canonical.
- Do not crop, stretch, recolor, redraw, or change the layout.
- Preserve the original aspect ratio and transparency (if any).
- Record source dimensions, format, and file size when an asset is added.
- If a WebP derivative is required, preserve the original composition and verify the output dimensions.
- Do not silently substitute an older concept image or an image from another project.

## Runtime rendering

The board should be rendered with its intrinsic aspect ratio (for example, `BoxFit.contain` in a constrained portrait layout). Never use `BoxFit.fill` to distort the board. If the board image includes UI chrome, determine which parts are artwork and which are interactive before placing overlays.

## Procedural elements

Do not upload separate pawn or dice images for the first implementation:
- Pawns are drawn using Flutter widgets/CustomPainter.
- Dice faces are drawn from the numeric value using vector shapes or CustomPainter.
- Glow, selection, movement, bounce, and roll effects are rendered at runtime.

This keeps game state separate from static artwork and avoids a large collection of redundant image assets.

## Asset verification checklist

- [ ] Board file exists at the canonical path.
- [ ] Icon file exists at the canonical path.
- [ ] Dimensions and aspect ratio recorded.
- [ ] No unintended crop, stretch, or visual modification.
- [ ] Flutter asset manifest includes the correct paths.
- [ ] Android launcher icon generated from the approved icon.
- [ ] Asset integrity tests pass.
