# Play Now gameplay contract

Baseline rebuild: `47c62c51483c1c26943151f640f2a623bfe52857`. Legacy comparison: `ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`.

- Play Now and Local use `ludo-lovers-current@1` through compatibility setup. VS Computer uses the same rules with AI seats.
- Classic, Quick, and Team Up honor `ModeRegistry` preview gates. Resume uses the rules and mode stored with the match.
- `MatchSession` accepts commands. `LudoGame` evaluates legality, captures, turns and winning. Changes to established rule behavior require a new profile version with saved-match coverage.
- The legacy and rebuild shared loops have the same 52 coordinates in the same order. Each seat traverses 51 shared positions and five private lane cells before finishing at progress 56.
- Entry offsets and turn order are Orange 0, Green 13, Magenta 26, Blue 39. Safe cells are 0, 8, 13, 21, 26, 34, 39 and 47.
- The diagonal links 4→5, 17→18, 30→31 and 43→44 each consume one route step. Preserve the approved artwork and measured anchors while changing the lobby.
- The logical route is frozen for this work. Physical-phone alignment of the connectors, stars and home-lane entrances remains an open visual acceptance item.
