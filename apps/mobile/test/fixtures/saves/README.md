# Historical local save fixtures

Frozen JSON emitted using the application source in main
`5d4ca3fb79d29e6ae8365f119ba31c13bb7e4348`, before the preferred UI stack merged.
The generator used the equivalent lib tree in local commit38f1d795 (verified with
an empty `git diff 5d4ca3f -- apps/mobile/lib`), Flutter3.35.7/Dart3.9.2.

MatchSession.local accepted one RollDiceCommand: matchId `upgrade-fixture`,
commandId `upgrade-pending-six`, expectedStateVersion0, active Orange, value6.
SavedMatch stores that session game, no AI seats, seed17 and local Unicode names
Éléonore/Renée/Māya. Configurations are local-current@2 with canonical2/3 seats.
These files are input fixtures; do not regenerate them using the code under test.

SHA256:

- local2:3d4791f404f1d84f0c8139c4eaeb9c2b09d434dece5b4efd299a201110a7d656
- local3:84434847e7fbc4409de6b68aed785cb856f944b7f4fe7c2f7c23a9376b6145c8

The regression opens current HomeScreen with the old raw saved preference, resumes
into MatchScreen, rejects a second roll while the accepted six is pending, moves
one pawn with repeated taps, and verifies the persisted version/command identity,
extra turn and name. It waits for existing artwork readiness before board input.
This is widget upgrade-contract coverage, not native process-death acceptance.
