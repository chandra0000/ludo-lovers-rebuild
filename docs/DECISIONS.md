# Decision log

Record durable product and engineering decisions here. Newest entries go first.

## 2026-11-10 — Versioned local match recovery

**Decision:** Persist a schema-versioned local match snapshot using the existing `shared_preferences` dependency. Restore it through an explicit Home-screen resume action; let the user discard it.

**Persisted state:** Four pawn-progress arrays, active player, pending dice result, winner, full rule-profile settings/version, state version, consecutive-six counter, accepted command IDs, AI seat assignments, and AI seed.

**Not persisted:** In-flight visual animation progress and transient events from the most recent transition. On resume, the UI renders the already-accepted engine state rather than replaying a partial visual hop.

**Reason:** Backgrounding, process recreation and accidental app closure should not silently discard an accepted local match. Keeping persistence local avoids introducing a backend dependency before local gameplay is accepted.

**Consequences:** Snapshot schema changes require explicit versioning and corruption handling. This does not provide cloud backup, cross-device sync or full event replay. Physical Android lifecycle acceptance remains required.

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


## 2026-11-10 — Pure structured pawn-move evaluation

**Decision:** Pawn legality is evaluated by a pure domain API returning a sealed valid/invalid result, rather than by a boolean-only check.

**Reason:** The same authoritative result must drive legal-pawn highlighting, transition validation, route animation, and reason-specific feedback. This avoids duplicating rules in Flutter widgets.

**Classic blockade:** The proposed Classic profile treats two or more pawns of the same opponent on an intermediate shared-track cell as a hard blockade. Destination stack protection, safe-cell co-existence and capture are evaluated separately. The compatibility profile retains its prior pass-through behaviour.

**Persistence:** Snapshot schema v3 stores the blockade setting. Schema v1/v2 snapshots migrate with blockade disabled to preserve saved-match semantics.

**Consequences:** UI feedback can consume typed invalid reasons without changing engine rules. Classic remains opt-in until the owner accepts the blockade and remaining rules; this implementation alone is not visual or product acceptance.
