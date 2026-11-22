# Task 1 repository and integration audit

**Decision: NO-GO for release.** Keep the review stack intact while Android default-renderer acceptance, iOS installed acceptance at the candidate head, and physical-device gates remain open.

## Source and scope

- Production baseline: `879f2b555c50575c5db066e0ac8bf530271a965a` on rebuild `main` (merged #43, following #44 responsive capture, #45 persistence recovery, and #47 evidence). Review candidate: `85c10f554847ec6529a3894b429f8e96d1b971a4` (#76, draft). The older repository at `ee7a4fe` is historical reference. [Rebuild](https://github.com/chandra0000/ludo-lovers-rebuild) · [Legacy](https://github.com/chandra0000/ludo-lovers)
- Confirmed each of the 23 PR bases is a Git ancestor of its head, each successive base equals the preceding head, and no individual head is reachable from `main`. Some functionality already exists on main, so use each base-to-head delta when reviewing. Open PRs #12, #23, #29, #39, #40 and #42 fall outside this chain and require patch-level overlap review before reuse.
- Verified equal Git blobs on the baseline and candidate for `apps/mobile/assets/images/board/ludo_board_glass.webp` (`324e4a84`), `apps/mobile/assets/images/logo/ludo_lovers_logo.webp` (`6794a429`), and `apps/mobile/lib/src/game/domain/board_geometry.dart` (`b0fc5644`). This checks source identity. Rendered pixel and pawn alignment acceptance are tracked by the existing fixtures.
- The Notion Project Hub confirms the locked visual identity, local-first scope, and server authority requirement for future online play. [Notion Project Hub](https://app.notion.com/p/3f5d7b2be1cc81fea8f5f4b450a42160)

## Git dependency graph

Each row depends on the row immediately above it. The first row depends on `main`. All rows were open and unmerged at capture.

| PR | Head | Scope |
| --- | --- | --- |
| [#54](https://github.com/chandra0000/ludo-lovers-rebuild/pull/54) | `a8edd17362f1` | Reconcile reviewed premium stack onto main and repair emulator checkpoint |
| [#55](https://github.com/chandra0000/ludo-lovers-rebuild/pull/55) | `23bcf306328d` | Extract turn coordination and read-only match rendering boundaries |
| [#56](https://github.com/chandra0000/ludo-lovers-rebuild/pull/56) | `8a066d95fd3f` | Build live three-zone premium HUD with a single canonical board transform |
| [#57](https://github.com/chandra0000/ludo-lovers-rebuild/pull/57) | `8117b6720d94` | Sculpt rounded glass pawns and refine authoritative dice settling |
| [#58](https://github.com/chandra0000/ludo-lovers-rebuild/pull/58) | `4faf005557c0` | Add versioned mode registry and approved two/three/four-seat Classic |
| [#59](https://github.com/chandra0000/ludo-lovers-rebuild/pull/59) | `a31fd2922e8a` | Implement approved Quick two-finish mode with deterministic duration evidence |
| [#60](https://github.com/chandra0000/ludo-lovers-rebuild/pull/60) | `a78be1e3afe8` | Migrate approved Team Up priority stacks and scheduled transfers into MatchSession engine |
| [#61](https://github.com/chandra0000/ludo-lovers-rebuild/pull/61) | `f0f46bfb1f3b` | Team Up: integrate progress, transferred turns and results into live gameplay |
| [#62](https://github.com/chandra0000/ludo-lovers-rebuild/pull/62) | `842068272116` | AI: respect Team Up capture attribution and friendly stacks |
| [#63](https://github.com/chandra0000/ludo-lovers-rebuild/pull/63) | `2822cb969e89` | QA: exercise installed local modes and require 29 live Flutter captures |
| [#64](https://github.com/chandra0000/ludo-lovers-rebuild/pull/64) | `608a92eb0177` | RFC: authoritative online Classic and private rooms |
| [#65](https://github.com/chandra0000/ludo-lovers-rebuild/pull/65) | `b732a6189779` | CI: add explicitly nonproduction Android app-bundle validation |
| [#66](https://github.com/chandra0000/ludo-lovers-rebuild/pull/66) | `d2d8dc1bf2ff` | Docs: Premium V2 verification receipts, feature parity and release readiness |
| [#67](https://github.com/chandra0000/ludo-lovers-rebuild/pull/67) | `f051cc485edf` | Match: unify mode-aware corner profiles and centered dice scaffold |
| [#68](https://github.com/chandra0000/ludo-lovers-rebuild/pull/68) | `be61c23451a0` | Match: royal full-screen backdrop, crown header and gold dice arena |
| [#69](https://github.com/chandra0000/ludo-lovers-rebuild/pull/69) | `5bfe64f41be6` | Match: add per-profile local chat, emoji and bounded feedback overlays |
| [#70](https://github.com/chandra0000/ludo-lovers-rebuild/pull/70) | `f70b9714722b` | Modes: add explicit FFA, 1v1, computer and Team-Up setup presets |
| [#71](https://github.com/chandra0000/ludo-lovers-rebuild/pull/71) | `903f54377613` | QA: harden AI cancellation, board pixels and installed royal screenshots |
| [#72](https://github.com/chandra0000/ludo-lovers-rebuild/pull/72) | `22bb509ec95a` | Docs: royal gameplay evidence, source receipts and release gates |
| [#73](https://github.com/chandra0000/ludo-lovers-rebuild/pull/73) | `50ae0cf14ac4` | UI: center logo between larger adaptive player profiles |
| [#74](https://github.com/chandra0000/ludo-lovers-rebuild/pull/74) | `70f0bf2051c4` | CI: bound Android checkpoint resources and preserve crash diagnostics |
| [#75](https://github.com/chandra0000/ludo-lovers-rebuild/pull/75) | `e6a6fa785a24` | QA: record and validate actual seeded Android gameplay |
| [#76](https://github.com/chandra0000/ludo-lovers-rebuild/pull/76) | `85c10f554847` | Branding: bundled royal typography, native launch identity and accessible gameplay |

## Architecture and feature inventory

| Area | Merged baseline and candidate status | Implementation and verification paths |
| --- | --- | --- |
| Engine and persistence | Main already has the command-driven local MatchSession, AI, stored-match recovery, and existing Classic rule/board tests. Candidate layers versioned configurations and Quick/Team Up rules onto that engine. | `apps/mobile/lib/src/game/application/match_session.dart`, `apps/mobile/lib/src/game/domain/ludo_game.dart`, `apps/mobile/lib/src/game/domain/mode_registry.dart`, `apps/mobile/lib/src/game/infrastructure/persistence/saved_match_store.dart`, `apps/mobile/test/match_session_test.dart`, `apps/mobile/test/restored_human_turn_test.dart` |
| Local modes | Candidate includes Classic FFA/1v1, VS Computer setup, Quick two-finish, and Team Up engine, UI, AI and installed scenario coverage. Owner approval and physical acceptance still gate release of the intended mode set. | `apps/mobile/lib/src/features/setup/mode_selection_screen.dart`, `apps/mobile/lib/src/features/setup/game_setup_screen.dart`, `apps/mobile/lib/src/game/domain/ai/seeded_ludo_ai.dart`, `apps/mobile/integration_test/` |
| Online, private rooms, Tournament | #64 carries an architecture RFC. Public multiplayer/private-room service and approved production Tournament rules and dependencies remain open. Profile chat and reactions are local presentation. | #64, `apps/mobile/lib/src/features/match/local_match_chat_sheet.dart`, `docs/engineering/ENGINE_RULES_MODES_MULTIPLAYER_PROGRAMME.md` |
| Rendering and responsiveness | Main has the calibrated artwork, movement presentation, pawn layout and dice. Candidate extracts turn coordination, adds the mode-aware scaffold, royal backdrop and corner-profile composition, and refines pawn/dice materials. Experimental #73 backdrop texture was reverted per the PR ledger. | `apps/mobile/lib/src/features/match/game_board_scaffold.dart`, `apps/mobile/lib/src/features/match/match_turn_coordinator.dart`, `apps/mobile/lib/src/game/presentation/glassy_pawn.dart`, `apps/mobile/lib/src/game/presentation/luxury_dice.dart`, `apps/mobile/test/board_route_regression_test.dart`, `apps/mobile/test/approved_board_asset_integrity_test.dart` |
| Branding and startup | #76 includes licensed fonts, generated Android and iOS branding assets, and readiness-based startup. Reuse this implementation and validate its native handoff. | `apps/mobile/lib/main.dart`, `apps/mobile/lib/src/startup_frame_gate.dart`, `apps/mobile/lib/src/features/splash/splash_screen.dart`, `apps/mobile/lib/src/theme/app_typography.dart`, `apps/mobile/native_branding/`, `apps/mobile/tool/test_native_branding.py` |
| Native configuration | CI generates Flutter native scaffolding. Branding overlays that scaffold in #76. The chain has APK/AAB and simulator evidence at earlier heads. Signing, final application identity and permissions, store privacy, and physical compatibility need release-build evidence. | `.github/workflows/flutter.yml`, `.github/workflows/cross-platform-acceptance.yml`, `apps/mobile/lib/src/portrait_orientation.dart`, `docs/quality/android-bundle-validation.md` |

## CI and artifacts

| Revision or evidence | Observed result |
| --- | --- |
| Main `879f2b5` | [Foundation passed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44000165028) and [cross-platform passed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44000164874). [Checkpoint cancelled](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44000164880). |
| #54 | [Android checkpoint passed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44006508670). Use as a historical installed control. |
| #73 | [Foundation passed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44522722182), [cross-platform passed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44522722183), and [checkpoint failed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44523207613). PR records responsive captures at 320×640, 360×800, 393×873 and 430×932. |
| #75 | [Seeded software/debug recording succeeded](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368) at QA commit `bdf08df`. The checked-in report records 58.7413 s at 360×800, 20.67 active median fps and 9.16 encoded average fps with idle holds. [MP4 ZIP](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368/artifacts/14695484241) · [Native screenshots](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368/artifacts/14695807675) |
| #76 `014bd8c` | [Foundation passed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013338050). [Cross-platform failed on installed iOS](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013338028). [Default Android checkpoint failed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013400655). [Seeded recording job failed](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013353444) and did upload [candidate video](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013353444/artifacts/14750532631), [native screenshots](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013353444/artifacts/14750512641) and [diagnostics](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45013353444/artifacts/14750847054). |
| #76 `85c10f5` | [Foundation](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050576) and [cross-platform](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015050589) and the [seeded recording](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591) were in progress at capture. The [automatic checkpoint](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085666) was skipped. Confirm latest results and obtain default-renderer evidence for this source revision. |

GitHub listed both recordings and returned artifact references. File retrieval into the audit shell returned HTTP 403, so this audit uses existing reports and job logs for recording evidence. Timestamped frame review remains open. This host had no Flutter, Dart or ADB on PATH at capture. No fresh mobile execution or measurements are claimed.

## Prioritized defect register

| Priority | Defect and evidence | Root cause status and verification |
| --- | --- | --- |
| P0 | Default Android checkpoint loses the device during installed acceptance. #76 job logged driver RequestData failure, ADB offline, and TCP 5554 refused at 10:43:49 UTC. | The emulator/transport loss is confirmed. Native cause remains open. #74's successful prebuild and bounded Gradle resources did not eliminate it. The documented 2 GB Jetify heap error was a separate build failure. Inspect `.github/workflows/android-integration.yml`, `.github/scripts/android_integration.sh`, and `.github/scripts/summarize_emulator_crash.py`. Run same viewport, emulator image, runner and test sequence on a passing control and the candidate, then vary only the renderer. Preserve QEMU/host, ADB, logcat, and app/driver evidence on failure. |
| P0 | #76 `014bd8c` software recording logged a failure in Flutter binding frame timing at 10:44:32 UTC. | The #76 ledger traces this to widget-owned first-frame deferral changing state during render finalization. `85c10f5` moves deferral before `runApp` and releases it post-frame. Confirm with the regression test plus clean launcher-to-home and seeded native capture. |
| P1 | #76 `014bd8c` iOS installed test reported an active SemanticsHandle at teardown at 10:48:09 UTC. | Ownership is unresolved. Inspect `.github/scripts/ios_simulator_integration.py` and `apps/mobile/integration_test/app_navigation_test.dart` with accessibility activation and handle counts. Keep leak detection enabled. |
| P1 | Native performance and lifecycle acceptance remain open. | Variable-rate debug/software MP4 cadence cannot establish physical release performance. Use `docs/DEVICE_ACCEPTANCE_AND_PERFORMANCE.md` and `scripts/profile-android-frames.ps1` for physical Android profile/release measurement, and collect iOS timings, process-death/resume, and soak evidence. |
| P2 | Startup/fixture transitions, enlarged Team Up text, and feedback contrast have known fixes in the stack. | Review the #75 and #76 ledgers for source-specific observations. Re-run native cold/warm launch and installed scenarios at the final candidate and review at 100%/200% text, with safe areas and assistive technology. |

## Integration order

1. Review #54 against the merged baseline and verify how overlapping older PRs are represented. Review #55–#57 for presentation boundaries and engine-driven animation.
2. Review #58–#63 in dependency order, comparing engine rules, saved-match compatibility and local installed scenarios. Treat #64 as an RFC. Review #65–#66 for packaging and evidence.
3. Review #67–#73 for current UI and accessibility. Confirm the required viewports and artwork preservation against the latest rendering path. #74 and #75 provide isolation and recording evidence for diagnosis.
4. Finish Android default-renderer diagnosis, repeat #76 installed Android/iOS acceptance at an exact SHA, inspect the new footage, and document device results before proposing integration. Keep subsequent fixes in targeted PRs against the smallest compatible base. Preserve ancestry when landing approved changes, or explicitly restack and rerun CI after any squash.
5. Require owner visual approval, physical Android/iOS results, signing readiness and store review before production. The audit provides no verified score upgrade to 9+/10.
