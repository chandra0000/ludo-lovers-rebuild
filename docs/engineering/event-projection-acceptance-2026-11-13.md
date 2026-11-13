# Event-derived movement presentation — regression guard

## Scope

This increment strengthens the pure `MatchMovePresentationPlan` boundary. An accepted move must contain exactly one `PawnMoved` event, belonging to the requested player and pawn. The event endpoints must remain within the authoritative progress range, with strictly positive movement. Duplicate or cross-seat movement batches now fail closed instead of animating one event and ignoring another.

## Regression coverage

- Existing tests cover yard entry, capture and extra-turn variations, multiple captures, exact-home feedback, winner precedence, and missing/mismatched events.
- New tests reject duplicate movement events and cross-seat movement requests.
- No board asset, route topology, game rules, `MatchSession` authority, or layout coordinates are changed.

## Verification required

- [ ] GitHub Actions strict formatting, analyzer, full Flutter tests and Android profile/release APK jobs pass on this PR head.
- [ ] Android device QA confirms animation remains aligned to the approved board and is not interrupted by duplicate input.
- [ ] Review event projection behavior after future engine event schema changes.

This is a defensive engineering increment, **not** artwork approval, device acceptance, or commercial release readiness.
