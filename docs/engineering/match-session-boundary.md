# Match command and session boundary

## Purpose

The match application layer is the single entry point for roll, move and pass
commands. The Flutter screen, local AI and any future transport adapter submit
typed commands; they do not call domain transitions directly.

## Command contract

Every command carries:

- `matchId`: prevents a command from being applied to another match.
- `actorId`: identifies the seat issuing the command.
- `expectedStateVersion`: optimistic concurrency guard.
- `commandId`: idempotency key.
- A typed action payload: dice value, pawn index, or pass.

`MatchSession.execute` validates match identity, non-empty/unique command ID,
expected state version and the active seat's actor identity before calling
`LudoGame`. The immutable domain engine remains authoritative for legal
movement and rule-profile behavior.

Accepted results return the next immutable session and the ordered events
emitted by the engine. Rejected results retain the original session and expose
a typed rejection reason. No rejected command can partially mutate state.

## Replay

`MatchSession.replay` applies a recorded iterable of accepted commands to a
known initial session. It aborts at the first rejected command. Replaying the
same commands against the same snapshot and actor map must reproduce the same
snapshot and ordered domain events.

The command list is supplied by the caller; this boundary does not yet provide
durable command-log storage, networking, authentication, matchmaking or server
authority. Those are intentionally out of scope.

## Local integration

The local match screen maps each player seat to a local actor identity. Human
rolls, AI rolls, pawn moves and automatic no-legal-move passes all pass through
the same session. The saved game snapshot continues to preserve the domain
state version and accepted command IDs. A resumed local match reconstructs a
local session around that snapshot.

## Validation

Focused tests cover valid roll/move/pass, wrong match, wrong actor, stale state,
duplicate command IDs, invalid actions, no-mutation rejection, replay
determinism and actor-map validation. The Android integration smoke test
repeats home → setup → local match → home navigation three times.
