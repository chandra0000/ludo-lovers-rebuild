# Ludo Lovers — premium match composition and rendering acceptance

**2026-11-13 | Release status: NO-GO until physical-device and owner approval.**

## Canonical assets and non-negotiable preservation

- Approved full portrait source: `apps/mobile/assets/images/board/ludo_board_glass.webp` (810×1440).
- Source SHA-256: `f852ff2c8e905bdef2d8772e082722b24acdbd8111152c660ad3246ed2c5c3a1`. This asset must not be modified or regenerated.
- Bundled application mark: `apps/mobile/assets/images/branding/ludo_lovers_icon.webp`. The live game now reuses it rather than inventing another brand mark.
- Existing avatar sources: `board/extracted/avatar_{aldo,you,bob,emma}.webp`; four color-coded live badges remain presentation-only.
- Existing glass pawn renderer and deterministic `MatchSession` are unchanged.
- Existing `LuxuryDiceButton` is a genuine animated six-face 3D cube. The final face is supplied by the authoritative match command. Do not add a second dice control.

## Implemented in this review PR (subject to CI)

1. `MatchSurfaceChrome` fills 9:16 letterboxing on taller phones using subdued dark-gold rails, **without cropping or stretching** the gameplay stage. The mathematical 576×1024 canvas and all pawn coordinates remain fixed.
2. `MatchBrandMark` shows the committed approved brand icon at the top-center of the live match, between the top two player badges.
3. `MatchProfilesLayer` keeps all four existing avatar images, puts the player name and LOCAL/BOT/ONLINE/OFFLINE status on separate lines, sets a single accessible badge label, bounds image decoding to 192px, and raises bottom badges to avoid the control dock.
4. Chat remains local-only. Quick emojis are directly accessible from a standalone 84×84 canvas control, with an accessible picker, a two-second on-board reaction toast and a live-region announcement. Reactions sent through the existing chat sheet also appear on the board.
5. Footer chat and more controls are now 84×84 logical canvas units, providing ~52.5dp physical touch regions on a 360dp-wide portrait screen with width-based stage scaling.

## Regression coverage added

- `test/match_surface_chrome_test.dart`: both rails, committed logo, board, six-face cube, chat, quick reactions, more menu, 48dp control targets on compact viewport, picker behavior and reaction dismissal.
- `test/local_match_chat_sheet_test.dart`: local chat emoji invokes presentation callback.
- Existing `test/phase3_responsive_board_test.dart` must still pass on 360×780, 393×873 and 412×915; the stage aspect ratio and every tested pawn anchor must remain unchanged.
- Existing screenshot and asset-integrity checks must still pass. CI pixel-color smoke tests are **not** proof of owner-approved appearance.

## Remaining P0 review gates

- **Visual parity:** Compare a fresh CI match screenshot against the user-approved full portrait art; note the live screen intentionally uses the existing board-only crop behind dynamic UI. A future cleaned *derivative* of the approved full composition must preserve original board pixels and be visually approved before being enabled.
- **Logo approval:** The bundled app logo is used; no unverified Canva image replaces it. If the recently uploaded Canva logo is a newer revision, compare it against the existing approved logo before switching.
- **Device validation:** On 6.1–6.9-inch Android phones, check density 1×/2×/3×, display cutouts, 360×780, 393×873, 412×915 layout, font scale 1.0/1.3/1.5, TalkBack, keyboard-open chat, taps, portrait-only rotation and 20-minute play.
- **Performance:** Profile cold start median <=3s, 60Hz p95 <=16.7ms, slow frames >33.3ms <1%, memory 0/5/20min and 10 navigation cycles; only mark passed with actual physical device traces.
- **Gameplay acceptance:** Classic profile remains opt-in pending rule/visual owner sign-off; do not infer game rule correctness from these UI changes.
- **Distribution:** Signed release AAB / API36+ Play compliance is a separate uncompleted gate.

## Change protocol

Review the PR branch, run formatting, analyze, unit/widget tests and Android builds. Review the PR screenshot artifacts visually. Merge only after green checks and code review. Never alter the canonical source art in conflict resolution. Record owner approval and physical-device evidence separately.
