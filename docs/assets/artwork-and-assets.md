# Artwork and asset contract

## User-supplied canonical assets

The user intends to provide only two source images for the first milestone:

| Purpose | Canonical repository path | Status |
|---|---|---|
| Board artwork | `apps/mobile/assets/images/board/ludo_board_glass.webp` | Present and registered in Flutter assets; 810×1440 WebP |
| App launcher icon | `apps/mobile/assets/images/branding/ludo_lovers_icon.webp` | Present and registered in Flutter assets; launcher generation pending |

The app icon is used for Android launcher branding, not as an in-game board layer.

## Preservation requirements

- Treat the supplied source artwork as canonical.
- Do not crop, stretch, recolor, redraw, or change the layout.
- Preserve the original aspect ratio and transparency (if any).
- Record source dimensions, format, and file size when an asset is added.
- If a WebP derivative is required, preserve the original composition and verify the output dimensions.
- Do not silently substitute an older concept image or an image from another project.

## Runtime rendering

The supplied board-named WebP is a full-screen 9:16 game composition, not a board-only texture. It includes the player portraits/names, board, decorative die, turn label, and bottom controls. Preserve the entire composition and intrinsic aspect ratio; never crop, stretch, recolor, or redraw it. Treat baked-in UI as static artwork unless an intentional live overlay replaces it. The runtime board coordinate rectangle must be measured within the full-screen image, not assumed to cover the whole image.

## Procedural elements

Do not upload separate pawn or dice images for the first implementation:
- Pawns are drawn using Flutter widgets/CustomPainter.
- Dice faces are drawn from the numeric value using vector shapes or CustomPainter.
- Glow, selection, movement, bounce, and roll effects are rendered at runtime.

This keeps game state separate from static artwork and avoids a large collection of redundant image assets.

## Repository asset hygiene

The repository previously contained a reference-path copy of the board with the same Git blob SHA as the runtime board. That redundant working-tree copy has been removed; the canonical runtime board remains at `apps/mobile/assets/images/board/ludo_board_glass.webp`. The current tree contains only the board WebP and launcher WebP. The runtime manifest is intentionally explicit rather than including the entire asset directory.

## Asset verification checklist

- [x] Board file exists at the canonical path.
- [x] Icon file exists at the canonical path.
- [x] Board dimensions and aspect ratio recorded (810×1440, 9:16).
- [ ] No unintended crop, stretch, or visual modification.
- [x] Flutter asset manifest includes the correct paths.
- [ ] Android launcher icon generated from the approved icon.
- [ ] Asset integrity tests pass.
