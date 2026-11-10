# Ludo Lovers Classic — Rules v1.0

> **Status: Proposed — pending product-owner board/safe-cell approval and physical-device acceptance.**
>
> This is the proposed player-facing rulebook for the Ludo Lovers rebuild. It is not yet the shipped/default ruleset. Do not describe Classic as officially released until the acceptance gates in this document are closed.

## 1. Product scope

- The first acceptance target is **one local four-player match**.
- Seats are Orange, Green, Magenta, and Blue, in that fixed turn order.
- Each player has four pawns.
- The initial release does not claim support for two-player, three-player, online, team, quick-match, or tournament variants.
- Team, Quick Match, and Tournament are future, separately specified modes. They are not part of Classic v1.0.
- The approved board artwork and brand identity are unchanged by this rules proposal.

## 2. Rule profile and compatibility

| Profile | Engine identifier | Status | Behavior |
|---|---|---|---|
| Compatibility | `ludo-lovers-current@1` | Current default | Preserves the rebuild's original behavior |
| Ludo Lovers Classic | `classic@1` | Proposed target; opt-in | Applies the rules in this document |

**The current app default remains `ludo-lovers-current@1`.** `LudoGame.initial()` defaults to `LudoRuleProfile.currentV1`, and the match screen currently constructs the game without overriding that default. This proposal does not change it.

A match must retain the rule profile and version with which it was created. Loading an existing saved match must not silently switch its rules. Any future default-profile change requires a separate, reviewed migration/release decision.

## 3. Turn order and dice

1. Players take turns in this order: **Orange → Green → Magenta → Blue**, then repeat.
2. A standard six-sided die is used; each roll is from 1 to 6.
3. A pawn in its yard may leave only when its player rolls a six. The player places the pawn on that colour's entry/start square.
4. A player may choose any legal pawn for a roll. If a six can release a pawn or move a pawn already on the track, the player chooses the legal action.
5. A six grants one additional roll. This also applies when the six has no legal pawn move and the player must pass, unless it is the third consecutive six.
6. **Three consecutive sixes:** the third six is forfeited immediately. No pawn may move from that roll, the turn passes to the next active player, and the consecutive-six counter resets.

## 4. Movement and home

1. Pawns move clockwise along the 52-cell shared track.
2. Each player's route contains 51 player-relative shared-track positions (progress 0–50), followed by a private five-cell home lane (progress 51–55), and the final Home position (progress 56).
3. A pawn enters its own private home lane after completing its shared-track route. Home-lane cells are protected from capture and shared-track blockades.
4. A player must roll the **exact number** required to reach final Home. A roll that would overshoot is illegal for that pawn.
5. A player wins immediately when all four of their pawns reach final Home. The match ends; this is winner-takes-all Classic, not a placement/ranking mode.

## 5. Safe squares — mapped to the canonical board

The safe-square rule is tied to the existing, unchanged 810×1440 canonical artwork at `apps/mobile/assets/images/board/ludo_board_glass.webp`.

- The four player-coloured entry/start squares are safe.
- The four gold star squares are safe.
- Pawns on a safe shared-track square cannot be captured.
- The following table records the current route IDs, logical board cells (column, row), and source-artwork cell-centre coordinates (x, y in pixels).

| Route ID | Type / colour | Board cell (column, row) | Artwork centre (x, y px) |
|---:|---|---|---:|
| 0 | Orange start | (1, 6) | (96.5, 625) |
| 8 | Gold star | (6, 2) | (341, 427.5) |
| 13 | Green start | (8, 1) | (466.5, 377.5) |
| 21 | Gold star | (12, 6) | (664, 625) |
| 26 | Magenta start | (13, 8) | (712, 729) |
| 34 | Gold star | (8, 12) | (455, 940) |
| 39 | Blue start | (6, 13) | (351, 991.5) |
| 47 | Gold star | (2, 8) | (144.5, 729) |

The domain now names these groups separately as `BoardGeometry.startTrackCells` and `BoardGeometry.starTrackCells`; `safeTrackCells` is their union. Engine tests pin the route IDs and logical cells.

**Visual status remains pending.** The canonical artwork was inspected and the four coloured entry tiles and four gold star markers were mapped to the table above. The owner must still approve the mapping at full resolution, and it must be checked on a physical Android device. Keep `BoardGeometry.visualApprovalPending = true` until that approval is recorded. These coordinates are not permission to alter or replace the artwork.

## 6. Captures and protected stacks

1. A pawn may capture an opponent pawn only by landing on the same **unsafe shared-track cell**.
2. Under Classic, a landing may capture exactly one opponent pawn. The captured pawn returns to its yard.
3. A destination occupied by two or more opponent pawns is protected: the move cannot land there, and none of those pawns is captured. This applies even if the occupants belong to different opponents.
4. Safe squares and all private home-lane cells are protected from capture.
5. Capturing one opponent pawn grants one additional roll.

## 7. Blockades

1. Two or more pawns belonging to the **same opponent** on one shared-track cell form a hard blockade.
2. A moving pawn cannot pass through an opponent blockade. The blocked cell is an intermediate cell in the proposed path; the move is illegal even if the pawn would finish beyond it.
3. The destination is evaluated separately: landing on a protected opponent stack is also illegal (see Section 6).
4. If another pawn has a legal move, the player must choose another legal pawn.
5. If no pawn has a legal move, the player must pass the roll and the turn is resolved by the normal pass rule. A passed six still grants its extra roll, except when the roll itself was the third consecutive six (which is handled immediately as a penalty).
6. A player's own pawns may share a cell. An own-pawn stack does not block that player's movement.
7. A blockade exists only on the shared track; private home lanes are not blockade cells.

## 8. Bonus-roll resolution

Classic grants an additional roll for each of these conditions:
- Rolling a six.
- Capturing one opponent pawn.
- Reaching final Home with a pawn.

If more than one condition is satisfied by the same completed move, they grant **one additional roll total**, not stacked rolls. A winning move ends the match and does not grant a further turn. The third-consecutive-six penalty takes precedence and forfeits that roll.

## 9. Fair-play and engine contract

- Only moves accepted by the authoritative rules engine are legal.
- A rejected move must not change the prior game snapshot.
- Stale state versions and duplicate command IDs must be rejected.
- Human controls and seeded local AI must use the same game snapshot, rule profile, legal-move evaluator, and transition methods. AI must not implement a separate movement/capture/blockade ruleset.
- Game events must remain deterministic for a given accepted transition.

## 10. Phase 1–4 verification record

The rebuild currently contains the opt-in `classic@1` profile and implements the profile switches for finish bonuses, the third-six penalty, single-opponent capture, and hard blockades. The implementation review found:

| Rule | Engine behavior reviewed | Automated coverage |
|---|---|---|
| Six to leave yard / extra roll | Implemented | Existing engine tests |
| Third consecutive six forfeited | Implemented | Existing Classic test |
| Safe start/star cells | IDs and geometry mapped | New route-ID/cell regression test; artwork approval still pending |
| Single-opponent capture / protected destination stack | Implemented | Existing Classic tests |
| Intermediate hard blockade | Implemented | New pass-through, alternate-pawn, and forced-pass tests |
| Exact finish | Implemented | Existing Classic exact-finish test |
| One bonus roll when triggers overlap | Implemented with a single boolean resolution | Existing overlap test strengthened to assert one bonus event |
| First player to finish all four wins | Implemented | Existing engine win tests |
| Seeded AI follows supplied profile | AI uses engine legal moves | New Classic blockade AI test |

The tests are committed for CI execution. Do not report them as passing until the corresponding GitHub Actions run is green.

## 11. Acceptance gates before Classic becomes the default

Classic v1.0 may be promoted only after all of the following are complete:

- [ ] Product owner approves the safe-square mapping against the canonical artwork.
- [ ] Product owner approves the blockade semantics and destination-stack behavior.
- [ ] Engine unit tests pass for all Classic rules.
- [ ] Widget/integration coverage verifies turn resolution and human/AI hand-off under Classic.
- [ ] A full local four-seat match completes on a physical Android phone.
- [ ] The default-profile change and any saved-match migration are reviewed in a separate change.

Until then, `ludo-lovers-current@1` remains the default and this document remains **Proposed**, not the final public rulebook.
