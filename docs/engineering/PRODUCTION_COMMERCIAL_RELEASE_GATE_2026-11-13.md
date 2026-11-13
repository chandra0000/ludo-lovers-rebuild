# Ludo Lovers — production and commercial release gate

Status: **NOT APPROVED FOR MERGE OR COMMERCIAL RELEASE** as of 2026-11-13.

## Verified GitHub evidence
- PR #34: draft; base main; workflow run 43353104676 completed successfully on head b99f1555b103b29e558741bff020c3a8e2d23b6d.
- PR #35: draft; stacked on PR #34; latest changes include typed event-derived capture FX and tests. No workflow runs were returned for the latest checked head. This does not establish pass/fail.
- Do not merge #35 before #34. After #34 is merged, retarget/rebase #35 and run CI again on its exact final head.

## Engineering gates (all required)
- [ ] CI green on the exact PR #35 head: `flutter analyze`, full `flutter test`, Android debug and release build.
- [ ] Visual effects remain presentation-only; capture count comes from accepted `PawnCaptured` events. Verify ordinary, capture, multi-capture, winner and reset scenarios.
- [ ] Final pawn bounce synchronized with movement completion; capture sparkles, landing pulse, emoji animation, reduced-motion support; verify no interaction obstruction or duplicate FX.
- [ ] Compare actual device screenshots to approved glass-board artwork; validate 52-track geometry, pawn alignment, safe stars, no board crop or duplicate star rendering.
- [ ] Device matrix: small/medium/large Android portrait (target 6.1–6.9-inch), cold start, resume, long matches, rematch, low memory, offline, 2P/4P supported modes.
- [ ] Measured frame-time, startup, memory and crash/ANR results, with evidence attached to PR; no black screens.
- [ ] Accessibility: touch targets, TalkBack, active-turn clarity, reduced motion, contrast, chat/emoji focus and safe areas.
- [ ] Signed release AAB, Play Console internal testing, app signing, versioning, store listing, age rating, data safety and privacy policy.
- [ ] Security/privacy: inventory SDKs and permissions; disclose chat/analytics/ads appropriately; verify any backend authentication, abuse protections and data retention if added.

## Commercial launch decisions
- [ ] Select monetization model (ad-supported, optional cosmetics, or other). Do not introduce intrusive ads over the board or imply real-money wagering.
- [ ] Validate rights/licenses for logo, board art, avatars, audio, fonts and third-party assets. Avoid copying Ludo King proprietary art or branding.
- [ ] Decide whether online multiplayer, purchases, leaderboards, and cloud accounts are in v1. Do not advertise features that are not implemented.
- [ ] If purchases are included, implement Google Play Billing and restore/refund flows; test them before release.
- [ ] If ads/analytics are included, integrate consent and disclosure flows where required; measure impact on frame time and player retention.
- [ ] Complete QA acceptance and product-owner approval. Only then mark PRs ready, merge in dependency order, and publish first to an internal testing track.

## PR acceptance evidence template
For each gate attach: exact commit SHA; CI run URL; test summary; device model/Android version; screenshots/video; performance trace; defect IDs; reviewer sign-off. A checkbox is complete only with recorded evidence.

## Architecture rule
`MatchSession` alone determines dice, legal moves, captures, bonuses, turn order and victory. Rendering, celebrations, player badges and social reactions are visual projections and must never alter authoritative state.
