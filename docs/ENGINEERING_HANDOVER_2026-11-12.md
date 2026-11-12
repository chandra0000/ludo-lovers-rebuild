# Ludo Lovers — Engineering Handover and Production Roadmap

**Updated:** 2026-11-12  
**Source of truth:** `chandra0000/ludo-lovers-rebuild` (legacy `chandra0000/ludo-lovers` is reference only).  
**Status convention:** IMPLEMENTED = source/PR evidence; VERIFIED = tests or a run tied to an exact SHA; PENDING = needs acceptance; PLANNED = not shipped.

## 1. Current position

The rebuild has a local four-seat match foundation, immutable rules/state, typed `MatchSession` commands with actor/match/version/idempotency checks, deterministic replay tests, saved local match snapshots, AI difficulties, board and pawn geometry regression tests, animated dice/pawns, local chat/reactions, profile badges, and Flutter/Android CI infrastructure. See `docs/PROJECT_STATUS.md`, `docs/engineering/match-session-boundary.md`, and PRs #22/#24 for detailed implementation evidence.

**Do not equate source implementation or an earlier green CI run with release acceptance.** Confirm the latest head SHA, workflow status, emulator/device evidence, and owner approval before promoting a status to VERIFIED.

## 2. Delivered versus outstanding

| Area | Delivered / documented | Remaining acceptance or work |
| --- | --- | --- |
| Core rules | 52-cell shared track, seat routes, yard/home, captures, safe cells, exact finish, win, versioned profiles; engine regressions | Approve Classic rulebook and edge cases; validate full human/AI match on device |
| Session boundary | Typed roll/move/pass commands, authorization, stale/duplicate rejection, replay tests (PR #22) | Preserve invariants across future online transport and multiplayer |
| Match orchestration | PR #24 describes extracted command, persistence, AI scheduling, animation lifecycle and delayed-turn controllers | Check PR head/merge state and CI; ensure no stale callbacks or lifecycle regressions |
| Artwork | Canonical approved glass composition and extracted renderer assets; automated asset/anchor checks | Owner sign-off on exact uncropped artwork, dynamic HUD parity, pawn/dice alignment and touch targets |
| UI | Branded home, local setup/match, dice/pawn animation, controls, local chat and avatars | Polish onboarding, win/rematch, visual hierarchy, responsive 6.1–6.9-inch portrait screens |
| Save/resume | Versioned local snapshots and recovery tests | Process-kill/relaunch, corruption and migration checks on real Android |
| AI | Seeded difficulty levels and legal-move selection | Device match soak tests and measured fairness/difficulty |
| CI | Formatting, analysis, Flutter tests, APK builds; opt-in emulator checkpoint | Validate latest exact SHA; device test matrix; frame pacing, memory, startup, thermal and accessibility |
| Modes/network | Architecture and rule-profile groundwork | Team Up, online friends/private rooms, matchmaking, tournaments, 3-/6-seat support are future milestones, not release claims |

## 3. Non-negotiable product contracts

1. Keep the approved original glass-board image and brand identity; never silently crop, recolor, stretch or replace it. Source artwork is a portrait composition, not merely a square board texture.
2. Keep the pure rules engine authoritative; UI/Flame render accepted state only. All actions go through `MatchSession` with actorId, matchId, expected stateVersion and unique commandId.
3. Preserve Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`; turn order Orange → Green → Magenta → Blue.
4. Preserve current compatibility rule profile as default until the proposed Classic profile is expressly approved.
5. Do not expose unfinished online, team, tournament or seat-count options as working modes.
6. Do not declare the app production-ready on the basis of CI alone.

## 4. Priority execution plan

### P0 — Stabilize the current baseline
- Inspect latest `main` and active PR heads, especially PR #24; capture commit SHA and exact Actions run URLs.
- Run `dart format --output=none --set-exit-if-changed .` (scoped to Dart source as appropriate), `flutter analyze --fatal-infos`, `flutter test`, profile/release APK builds, and emulator navigation smoke checkpoint.
- Check command idempotency, deterministic replay, interrupted animation, delayed AI callbacks, save/resume and match exit/restart.
- **Done when:** all required checks pass at the same candidate SHA and no P0 crash/black-screen regression remains.

### P0 — Exact visual and device approval
- Compare actual full-screen captures with the owner-approved portrait glass artwork; preserve its entire 9:16 composition.
- Verify board anchors for all 52 track cells, 20 lane cells, 16 yard sockets and finish, including 51→0 wrap, diagonal visual connectors and safe stars.
- Validate pawn tap areas, dice visibility/animation, avatars, chat/more controls, no clipped elements and portrait screens from 6.1 to 6.9 inches.
- Record device model, resolution, Android version, APK SHA, screenshots and owner decision.
- **Done when:** explicit owner sign-off plus reproducible physical Android acceptance evidence.

### P1 — Gameplay completion and UX
- Finalize Classic rules decisions and run deterministic edge-case tests (six penalties, captures, blockades, safe cells, extra turns, exact finish).
- Polish home → mode → setup → match → winner → rematch/exit, including accessibility and recovery.
- Add testable end-to-end scenarios and real-device AI-vs-human soak runs.
- **Done when:** no rule ambiguity, dead-end UI, or broken win/rematch flow.

### P1 — Performance and release engineering
- Capture release-build cold start, frame timing (median/p95/p99), memory, battery/thermal, APK size and lifecycle stability on target devices.
- Set budgets only after measurements; fix identified bottlenecks rather than guessing.
- Prepare launcher icon, signing, versioning, privacy disclosures, crash reporting, Play Console listing and staged rollout.
- **Done when:** recorded thresholds and release checklist pass, not merely APK compilation.

### P2 — Multiplayer and extended modes (separate milestones)
- Design server-authoritative command validation, reconnection, replay, anti-cheat and telemetry before online rooms.
- Add private/friend rooms and matchmaking by party size, mode, skill, latency/region, wait time and optional economy buckets; widen search carefully and only use bots transparently.
- Implement Team Up and tournaments only with versioned rules, tests, UX and backend acceptance. Treat 2/3/4/6-seat support as separate design/rules scope.
- **Done when:** dedicated backend, security, load and device acceptance criteria pass.

## 5. Codex / Antigravity handoff procedure

1. Read `README.md`, `docs/README.md`, `docs/PROJECT_STATUS.md`, `docs/DECISIONS.md`, the rules, board calibration, architecture, session boundary, quality and device-acceptance documents.
2. Inspect current branch/PR/CI state before editing. Never assume a previously reported green pipeline covers the latest head.
3. Choose **one** milestone; write the affected files, invariant contracts, acceptance tests and visual evidence requirements before implementation.
4. Work on a dedicated branch and submit a reviewable PR. Preserve the legacy repository as read-only reference.
5. Run formatting, analyzer, tests, builds and any relevant emulator checks; attach exact SHA, logs, screenshots and benchmark outputs. Clearly identify checks not run.
6. Update this handover and the relevant specialist docs in the same PR. Do not mark tasks complete until evidence and required owner approval exist.

## 6. Immediate next action

**First:** reconcile PR #24 against the latest `main` and its exact CI result; **second:** obtain physical Android screenshots and owner approval for the full glass-board/HUD layout; **third:** complete gameplay and release gates before starting online matchmaking.

**Evidence limitations:** This handover is based on repository README/status documents and PR descriptions available on 2026-11-12. PR descriptions are implementation claims, not independent verification of their latest CI results. No physical-device approval is asserted here.
