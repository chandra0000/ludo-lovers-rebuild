# Premium Match UI Refinement — approved direction and implementation gate

## Purpose
Use the user-selected premium dark, cyan and gold concept **as styling inspiration**, while retaining the approved Ludo Lovers glass board and gameplay. This branch starts from current main and is isolated from existing pull requests.

## Non-negotiable visual invariants
- Preserve the exact approved board image, 576x1024 logical canvas and Rect L17 T205 R559 B747.
- Preserve the 15x15 board grid, 52-cell shared route, all 16 pawn positions, safe cells, home lanes and four brand colors: orange #FF8928, green #33FF28, blue #289EFF, magenta #F428FF.
- Preserve approved logo, portrait layout and MatchSession authority. UI and effects cannot decide or mutate gameplay.
- The uploaded reference depicts a different game; **do not copy its gem grid, combat cards, score, or crown**.

## Target layout
- Four compact player avatar/profile areas, with accessible active-turn indicators and waiting/AI states.
- Full uncropped board as primary focus; decorative halo remains exterior only.
- Prominent, accessible Roll dice control; Choose a pawn and AI thinking states; adjacent legal pawns must be selectable without precision taps.
- Chat and emoji actions must be discoverable, not obstruct board, and respect safe areas.
- Restrained cyan highlights and gold trim over existing dark theme; avoid overpowering brand pawn colors.

## Implementation phases
1. Obtain completed Canva design and compare it against the exact approved board asset and current rendered match screenshot. Approve a specific visual target before altering widgets.
2. Apply styling in match-specific presentation widgets only; use existing theme tokens and extracted components. No gameplay logic changes.
3. Capture screenshot golden tests at 393x873 and other representative portrait sizes. Pixel-compare approved board interior and verify geometry/pawn alignment.
4. Verify 48x48 dp hit targets, TalkBack announcements, contrast and reduced-motion behavior.
5. Verify synchronized landing and capture FX are driven solely by accepted events; test animation cancellation and rematch.
6. Run dart format, flutter analyze, full flutter test, Android profile/release builds; inspect CI artifacts and real-device recordings before requesting review.

## Current status
- Dedicated feature branch created; no UI changes or merge approved by this document.
- Canva generation reported in progress at handoff. The finished editable design and board-accurate visual comparison are **not yet verified**.
- Do not declare commercial readiness without actual screenshots, device performance, licensing, privacy and Play Store release checks.
