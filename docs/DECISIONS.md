# Decision log

Record durable product and engineering decisions here. Newest entries go first.

## 2026-11-10 — Static board with programmatic game pieces

**Decision:** Use the user's supplied board artwork as a static background. Render pawns, dice, highlights, and effects programmatically in Flutter.

**Reason:** The game pieces are stateful and animated. Drawing them at runtime avoids separate image uploads for every pawn/dice face and keeps visual state synchronized with the game engine.

**Verified source detail:** The supplied 810×1440 portrait WebP is a full-screen game composition, not a board-only image. It includes static player portraits/names, the board, a decorative die, and bottom controls. Preserve the full image; map the actual board region inside it for pawn geometry and place intentional interactive overlays over baked-in UI where needed.

**Consequences:** Board coordinates must be calibrated against the board region inside the full-screen artwork. Pawn and dice rendering require widget/custom-painter tests and animation QA.

## 2026-11-10 — Only two required user image uploads for the first milestone

**Decision:** The user will provide the canonical board image and app icon only.

**Paths:**
- `apps/mobile/assets/images/board/ludo_board_glass.webp`
- `apps/mobile/assets/images/branding/ludo_lovers_icon.webp`

**Consequences:** Pawns and dice are generated at runtime; no separate pawn or dice assets are required.

## 2026-11-10 — Local-first first milestone

**Decision:** Complete one four-player local match before adding online features or alternate modes.

**Reason:** Stabilize rendering, game rules, and touch interactions before expanding scope.
