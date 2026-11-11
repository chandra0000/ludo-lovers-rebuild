# Engine, Rules, Modes and Multiplayer Readiness Programme

**Status:** Engineering plan and migration contract  
**Product source of truth:** `ludo-lovers-rebuild`  
**Reference only:** `ludo-lovers` (legacy)  
**Baseline:** rebuild `main` at `10c61849eb4ba894231d55bcd8268de702e6f067`; legacy `main` at `ee7a4fe2ffcdde93f2945df345acec08e8f87a5f`.

## 1. Non-negotiable engineering rules

1. The rebuild is the only active product implementation. Legacy code is evidence and a source of test cases, not a second product branch.
2. The domain engine is authoritative. Widgets, animations, AI, local persistence and future network transports may request actions but must not implement or bypass game rules.
3. Every ruleset and mode is named, immutable and versioned. A saved or networked match keeps the exact ruleset version with which it started.
4. Never silently reinterpret an existing saved match when defaults change. Provide explicit migrations and compatibility tests.
5. No gameplay mode is marked available until its rules, state invariants, UI flow, save/restore behavior and acceptance tests are complete.
6. Board geometry and approved artwork are independent from rules. Do not change or crop the canonical board asset to accommodate a mode.
7. CI/emulator success is not physical-device visual or performance approval.
8. Do not introduce a backend, economy, ranked matchmaking or network dependency as part of local-mode work. Prepare stable boundaries first.

## 2. Repository comparison and legacy recovery inventory

### Rebuild strengths to preserve

- Immutable `LudoGame` state and typed move evaluation.
- Shared `legalPawnIndices` / `movePawn` rule path.
- Versioned rule profiles, state versions, command-id deduplication and typed transition events.
- Central `BoardGeometry` contract, measured anchors and independent presentation layer.
- Local saved-match recovery, deterministic engine-constrained AI, widget and integration tests.
- Strict Flutter format/analyse/test/build CI.

### Legacy features and evidence to recover selectively

| Legacy capability/evidence | Rebuild destination | Migration policy |
|---|---|---|
| Two-player local setup | Mode/setup configuration | Reuse engine seat configuration; never fork movement rules |
| Four-player local | Existing Classic/local mode | Preserve as baseline |
| VS AI | Existing seeded AI seats | Keep AI as a policy choosing only engine-legal actions |
| Team Up 2-vs-2 | Separate mode + versioned Team Up profile | Port rules and tests, not legacy engine wholesale |
| Team Up scheduled-seat transfer | Domain turn-resolution policy | Keep scheduled seat distinct from active teammate recipient |
| Friendly teammate stacks and opposing-team cell priority | Explicit Team Up occupancy/capture policy | Test multi-occupant and departure-order edge cases |
| Team victory | Team result policy | Must not end when only one teammate finishes |
| Legacy board topology and route audit tests | Rebuild geometry acceptance suite | Reconcile against canonical artwork before accepting coordinates |
| Repeated navigation, lifecycle and phone viewport tests | Rebuild integration suite | Rebuild against current widgets and keys |

The legacy tree exposes 2P, 4P, VS AI and Team Up mode flows. The rebuild already has 4P/local and seeded AI foundations; 2P is a configuration of the same engine, not a second engine. Team Up is the main gameplay-mode port. Do not infer that online rooms or tournaments are implemented in the legacy project.

## 3. Target architecture

Keep the current lightweight app and introduce seams only where they solve real coupling.

- **Domain:** immutable match state, player/seat identity, pawn progress, ruleset, legal-action evaluation, turn resolution, results and typed events. No Flutter, storage, HTTP, socket or screen-coordinate imports.
- **Mode configuration:** mode ID/version, seat/team layout, eligible controllers (human/AI), ruleset ID/version, victory policy and supported local/network capability.
- **Application/session layer:** accepts commands with match ID, actor, expected state version and idempotency key; invokes the domain transition and returns accepted state plus events or a typed rejection.
- **AI policy:** receives a read-only state and legal actions; returns a choice. It cannot mutate state or roll dice itself.
- **Persistence adapter:** stores a versioned snapshot and, when introduced, a replayable command/event log. Storage remains outside the domain.
- **Presentation:** renders accepted state and animates events. Animation progress never feeds back into legality.
- **Transport adapter (future):** local in-process adapter today; authenticated online transport later. Both call the same application command boundary.
- **Authoritative service (future):** validates actor, turn, expected version, idempotency, ruleset and dice result. Client prediction is optional presentation only; the server's accepted transition is canonical.

### Multiplayer-ready command contract

A future command envelope should carry:
- `matchId`, `commandId` (idempotency key), `actorId`, `expectedStateVersion`, `type`, and validated payload.
- Accepted results should carry monotonically increasing `stateVersion`, ordered event sequence, ruleset/mode version and resulting state hash or canonical snapshot reference.
- Reject stale, duplicate, out-of-turn, malformed and illegal commands without mutating state.
- Never trust client-provided dice outcomes, winner declarations, rewards or pawn positions in online play.
- Keep player IDs distinct from local colour/seat labels; team membership is part of immutable match configuration.

Do not add a socket client or server now. First make the local application command boundary deterministic, testable and transport-independent.

## 4. Rules programme

### Phase R0 — rule audit (no default changes)

- Trace every current `LudoRuleProfile` field to its evaluator and turn-resolution branch.
- Verify yard entry, own stacking, capture, safe cells, protected stacks, home lane, exact finish, no-legal-move, extra six, capture/finish bonuses, third-six penalty and winner completion.
- Confirm Classic v1 proposal and board safe-cell IDs against the canonical asset and product-owner decision.
- Add table-driven tests for each rule and combinations; assert both accepted state and ordered events.
- Keep compatibility profile and existing snapshots behavior unchanged.

### Phase R1 — explicit profiles and migration

- Promote only approved Classic rules into a named, immutable profile.
- Preserve existing profile IDs and schema migrations; do not repoint an old ID to new semantics.
- Validate profile IDs/versions and reject malformed or unsupported combinations.
- Test schema-v1/v2/v3 restoration and duplicate/stale command rejection.

### Phase R2 — mode policies

- Keep common movement/geometry in one engine.
- Add mode-specific policies for seat count, teams, turn recipient, cell occupancy/capture and victory.
- Avoid boolean flag explosion: use cohesive immutable policy types when a rule differs structurally.
- Team Up must support scheduled Orange → Green → Magenta → Blue rotation, teammate turn transfer after a seat finishes, bonus-roll ownership, friendly stacking, safe-cell protection, deterministic mixed-team stack resolution and team victory.
- Add a rules compatibility matrix so a mode cannot combine unsupported policies accidentally.

## 5. Performance programme

Performance work must begin with reproducible measurement, not speculative micro-optimisation.

### Engine benchmarks

Create deterministic benchmark scenarios for:
- initial-state creation;
- legal-action enumeration in sparse and dense board states;
- move evaluation across yard, shared track, home lane, capture, stack and blockade cases;
- state transition/event generation;
- snapshot encode/decode and saved-match recovery;
- AI decision for Easy/Medium/Hard with fixed seeds.

Record device/runner, Flutter and Dart versions, build mode, warm-up count, iteration count, median, p95 and allocation/memory observations where available. Compare before/after on the same runner. Unit tests must not assert unstable wall-clock thresholds.

### UI/runtime profiling

On representative physical Android devices:
- startup cold/warm timings;
- frame timings for dice, pawn path, capture, stack and finish animations;
- memory at launch, 5 and 20 minutes, repeated match navigation, background/resume;
- battery drain against an idle baseline;
- image decode/cache and raster/GPU costs.

Optimise only evidenced hotspots. Likely areas to inspect include repeated derived-state computation, widget rebuild scope, expensive painter work, large asset decode, unbounded event/history retention and unnecessary snapshot serialization. Do not cache mutable domain state or weaken correctness for speed.

## 6. Test strategy and release gates

- **Domain unit:** exhaustive rules, invariants, legal-action parity, command idempotency, state-version checks, event order and snapshot migration.
- **Property/model tests:** generated legal command sequences preserve invariants; illegal commands leave state unchanged; replay from initial state reproduces the same state/events.
- **Mode contract tests:** every mode validates seat/team setup, allowed controller mix, turn schedule, result policy and profile compatibility.
- **AI tests:** legal-only decisions, determinism, difficulty separation, multi-seed win-rate/decision-quality evaluation; no claim of strength from single tactical examples.
- **Widget/integration:** setup navigation, board rendering, pawn selection, stack chooser, forced pass, turn indicators, save/resume, repeated navigation and accessibility.
- **Golden/geometry:** canonical art hash, measured anchors, pawn footprints, stacks, hit targets and responsive viewports.
- **Performance:** stable benchmark artifacts plus physical-device profiling report.
- **CI:** formatting, static analysis, unit/property tests, integration tests, Android build and artifact retention.

Release gate: no mode is enabled by default until its rule-owner approval, full automated acceptance, canonical-board visual acceptance and required device checks are complete.

## 7. Delivery sequence and dependencies

1. Stabilise current PR #15 (Classic rule proposal) and PR #16 (AI difficulty/device gates). PR #16 currently targets PR #15; preserve that dependency and retarget only after #15 is merged.
2. Establish the baseline and engine benchmark harness on rebuild main; document current costs before changing algorithms.
3. Complete R0 rule audit and close gaps in tests without changing default rules.
4. Introduce the application command/session boundary and invariants/replay tests while retaining current UI behavior.
5. Port Team Up rules and tests selectively from legacy into a separate mode/profile. Do not port its legacy engine wholesale.
6. Add explicit 2P, 4P, VS AI and Team Up setup flows using shared engine and mode configuration.
7. Profile and optimise evidenced engine/UI hotspots.
8. Add local persistence compatibility for every supported mode.
9. Only after local mode acceptance, design the online authoritative service, authentication, matchmaking, reconnect protocol, secure dice, anti-cheat and data retention.

## 8. Definition of done for this programme

- One canonical rebuild engine and one canonical rules/profile registry.
- All shipped modes share the same legal-action and state-transition contract.
- Every mode has versioned rules, deterministic tests and save/restore coverage.
- No stale or duplicate command can mutate a match.
- Replay from accepted commands produces identical state and ordered events.
- Benchmarks have a recorded baseline and before/after evidence.
- No performance regression is accepted without explicit justification.
- CI is green on the final PR head.
- Physical-device visual/performance acceptance is recorded separately from CI.
- Online multiplayer remains a future adapter/service, not a claim of current capability.
