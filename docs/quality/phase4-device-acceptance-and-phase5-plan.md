# Phase 4 acceptance and proposed Phase 5 scope

## Verified automated Phase 4 evidence

- GitHub Actions run #911 (commit `70efbf57dc9b509c4d5bcc3b31920ad50c106154`) passed strict Flutter verification, Android profile/release APK builds, and Android API 35 emulator integration smoke.
- Deterministic 2,500-transition stress, snapshot immutability, and navigation integration tests are already tracked in `four-phase-gameplay-verification.md`.
- Automated success does **not** constitute physical-device or visual acceptance.

## Physical Android acceptance record (required before Phase 4 sign-off)

Record device model, Android version, screen resolution, refresh rate, APK variant, tested commit, and date. Save screenshot or video evidence for each item.

- [ ] Five consecutive home → match → exit → match journeys without blank screen or stale state.
- [ ] Cold launch, background/resume, and process-kill restore without duplicated or lost moves.
- [ ] Animated dice settles on the authoritative engine result; consecutive identical values each animate once.
- [ ] Pawn release, hop, capture, protected square, pass, exact finish, and victory/play-again.
- [ ] All sixteen starting sockets and representative track/home-lane/finish cells visually align with approved artwork.
- [ ] Portrait 6.1–6.9-inch-class devices: no clipping, stretched board, or unreachable touch targets.
- [ ] Landscape behavior documented; accessibility touch targets and TalkBack tested.
- [ ] Profile APK performance: frame jank, memory pressure, heat, and battery observations recorded.
- [ ] Original approved board artwork compared side by side with screenshots; user visual sign-off recorded.

Do not mark Phase 4 complete until the above evidence is reviewed. Do not alter the canonical board image as a substitute for calibration.

## Proposed Phase 5 — Classic match readiness and product polish

The repository's published verification programme defines Phases 1–4, **not** an approved Phase 5. The following is a proposal, not a pre-existing milestone.

1. Close Phase 4 device and visual blockers without weakening strict CI.
2. Add deterministic complete-match regression scenarios covering human and seeded AI, victory and replay, restore and command rejection.
3. Add accessibility and reduced-motion checks for dice/pawns, including a consistent final result.
4. Improve performance instrumentation on a real Android profile build; capture baseline and regression thresholds before optimization.
5. Only after Classic acceptance, separately scope additional modes, online multiplayer, and social features.

Acceptance: CI green, documented real-device evidence, approved board visuals, and no gameplay-rule regressions. Keep all work on the feature branch; do not merge into main without explicit authorization.
