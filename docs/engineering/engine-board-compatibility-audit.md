# Ludo Lovers — Engine and Board Compatibility Audit

## Sources and non-regression policy

- Legacy specification: `chandra0000/ludo-lovers/docs/game-rules/ludo-game-rules.md`.
- Legacy board acceptance: `chandra0000/ludo-lovers/docs/board-route-acceptance.md`.
- Current engine: `apps/mobile/lib/src/game/domain/ludo_game.dart`.
- Current board geometry: `apps/mobile/lib/src/game/domain/board_geometry.dart`.
- Current artwork: `apps/mobile/assets/images/board/extracted/board_exact.webp`.

The legacy repository is a **reference**, not a drop-in replacement: it explicitly calls parts of its board topology provisional. Do not copy its entire engine or coordinates into the rebuild without preserving state serialization, turn order, approved art, and existing tests.

## Rules compatibility matrix

| Rule | Legacy intended classic | Rebuild currentV1 | Rebuild classicV1 |
| --- | --- | --- | --- |
| Six to leave yard | Yes | Yes | Yes |
| Bonus roll on six | Yes | Yes | Yes |
| Bonus roll on capture | Yes | Yes | Yes |
| Bonus roll on finish | Yes | No | Yes |
| Third consecutive six ends turn | Yes | No | Yes |
| Capture only single opponent | Yes | No | Yes |
| Hard blockade | Configurable | No | Yes |
| Exact finish | Yes | Yes | Yes |

These are distinct game variants. Never silently change the default for an in-progress saved match. Explicitly select a rule profile when starting a match, persist its ID/version, and add deterministic tests for each profile before promoting Classic to default.

## Canonical board contract

- 15x15 logical grid, 52 shared track cells, 5 private home-lane cells per seat, centre finish.
- Seat entry offsets: Orange 0, Green 13, Magenta 26, Blue 39.
- Star indexes: 8, 21, 34, 47; safe indexes: 0, 8, 13, 21, 26, 34, 39, 47.
- Four intentional diagonal connectors: edges 4→5, 17→18, 30→31, 43→44. Do not 'fix' them without visual approval: the legacy audit establishes that strict orthogonality conflicts with the current four entry coordinates.
- Source geometry anchors were measured against a historical 810x1440 image, while the approved extracted board is cropped from an 864x1536 reference at (15,307), dimensions 835x851. **These coordinate spaces are not interchangeable.** A visual overlay/calibration gate must confirm the pawn centres align with the approved image; a passing logical-topology test is insufficient.

## Acceptance gates before release

1. `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --fatal-infos`, `flutter test`, and Android APK build must pass.
2. Automated tests must cover all four seats, safe-square capture immunity, single/multiple opponent stacks, blockades, third-six behavior, bonus rolls, no-legal-move turns, exact home finish, and persistence across rule-profile versions.
3. Render real Flutter screenshots at 360x800, 393x873, 412x915 and landscape; compare cell centres, all yard sockets, 52 track cells, 20 home-lane cells, and finish against the approved board image.
4. Confirm hit targets and visual pawn centres after scale/letterboxing, including 6.1–6.9-inch physical devices.
5. Do not mark visual topology approved or claim commercial readiness until physical-device checks are completed.

## External rules references

- https://ludo.alignitgames.com/games/ludo.html
- https://ludo.live/ludo-rules-explained-official-moves-safe-squares-capture-rules-and-common-variations

Rules vary by provider; the user-selected product profile is authoritative.
