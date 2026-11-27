# Public local seats and smaller dice

Owner-approved2026-11-27 change: add local2-/3-player matches, require opposite
colors for two players, reduce dice size and work toward evidence-based9/10.
"Shrink12%" is implemented as12% smaller (visual scale0.88), not a tiny12%-of-
original die. Its64×64 logical-pixel gesture target remains unchanged.

## Integrated starting point

#97 merged at400e1afeeec7860b7f74013ee6098af70b28addb after its reviewed checks.
#96 was updated without force to include that main, revalidated at34b53863d2949693ca9fd29a136becd097acdd70,
then merged atb19fbbbdb65a3d549783238f954a158b1f25be7e.
The feature is based on that resulting main, not an older presentation branch.
Security/foundation/cross-platform runs45929088607/45929088663/45929088643 all
passed for the #96 integrated head before its merge.

## Product and domain contract

- The public Local game supports2,3,4 participants through the existing setup
  selector and explicit public1v1/three-player entry buttons. All-human and AI
  setup use the same authoritative configuration. Names remain color-keyed.
- Two players: Orange(top-left) and Magenta(bottom-right),26 shared-route cells
  apart. Three players: Orange→Green→Magenta; Blue is inactive. Inactive profile
  placeholders stay in their existing visual quadrants; no pawn/turn is assigned
  to an inactive player. Four-player order remains Orange→Green→Magenta→Blue.
- Existing `local-current` configuration version1 remains four-seat-only, with
  the same old save decoding. The new2-/3-seat configurations explicitly use
  version2. Adjacent/noncanonical seats and mismatched versions are rejected.
  Older binaries cannot restore these newly introduced version2 matches; no
  backward-read compatibility for new features is claimed. Old four-seat saves
  remain supported by the new binary.
- The underlying `ludo-lovers-current@1` rule profile is unchanged. The extension
  changes seat membership, not entry/capture/finish/extra-turn/safe-cell rules.
  Classic, Quick and Team-Up keep their existing public preview/release gates.
- MatchSession remains authoritative for actors, commands, versions, legal moves
  and turn progression. No widget rule engine or duplicate coordinate table.
- The die's visual cube changes64→56.32 logical units, while layout/touch target,
  semantic result, result source, duplicate-tap guards and timing remain intact.
  Every mode using the actual MatchScreen receives the same visual reduction.
- Approved board/logo bytes, portrait layout, pawn shapes/anchors, turn identity,
  safe stars and board topology are unchanged.

## Verification

Initial feature regression reproduced unsupported local counts/missing public
entry points. Local final full suite464 tests PASS; focused30 tests PASS; final
nine dice/capture tests PASS; strict191-file format and fatal-info analysis PASS.
Two-/three-player seeded full matches complete deterministically, command IDs
remain idempotent, turns skip inactive seats, saves round-trip, restart preserves
seats and preview profiles remain locked.

The shared native/widget navigation harness now covers public local2/3 plus
existing Classic/Quick/Team-Up preview fixtures: setup, roll, restart, exit and
same-process saved resume. New native captures are named native-local-2-match
and native-local-3-match. Native CI conclusions must be read from this PR's exact
head; the harness change is implementation until those runs pass.

Actual Flutter PNGs were generated at320×640,360×800,393×873,430×932 for both
counts, with safe-area padding. All eight decode. The393×873 two-player and
320×640 three-player captures were visually inspected: opposite positions,
empty inactive yards, full square board and smaller die are visible. Tests
require the full64×64 die hit target and verify a tap near its edge is accepted
once, with animation settling on authoritative6 exactly once. Widget captures
are not Android installed or physical-device evidence.

## Remaining9/10 gates

The implementation does not assign itself9/10 or clear production release.
#74 still has a failed default-renderer checkpoint; #75 conflicts and #76's
premium typography/startup work remain in their reviewed dependency queue.
Physical midrange Android/iPhone profile/release traces, process-death/low-memory/
long-match acceptance, native screen readers, signing/store and owner visual
approval remain separate gates. Online authority still requires joint #90/#94
review and security/load acceptance. No multiplayer service is claimed here.
